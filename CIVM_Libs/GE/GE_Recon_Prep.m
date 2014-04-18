function [data, traj, weights, header] = GE_Recon_Prep(pfile_name, revision, rp_filename, offset, byte_order, precision)

if(nargin < 5)
    %Typically there is no offset to the header
    offset = 0;
    
    %Assume little endian format
    byte_order = 'ieee-le';
    
    % Can we read this from header? CSI extended mode uses int32
    precision = 'int16';
end

% Read the header for the correct rdb header revision
header.ge_header = ge_read_header(pfile_name, revision);

% Calculate trajectories according to pulse sequence
% Store important info from header
npts = header.ge_header.rdb.rdb_hdr_frame_size;%view points
nframes  = header.ge_header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;

% Read the image data
if(isempty(rp_filename) || ~exist(rp_filename))
    disp('No RP file found, using data in Pfile');
    rp_filename = pfile_name;
    remove_baselines = 1;
else
    disp(['Using Pfile for header and RP file for data. ' ...
        'No baselines will be removed.']);
    remove_baselines = 0;
end
fid = fopen(rp_filename, 'r', byte_order);
fseek(fid, header.ge_header.rdb.rdb_hdr_off_data, 'bof');
data = fread(fid,inf,precision);

% Data is complex (real and imaginery parts alternate)
data = complex(data(1:2:end),data(2:2:end));

% Separate baselines from raw data
nframes  = length(data(:))/npts;
data = reshape(data,npts,nframes);% Reshape into matrix

% Remove baselines
if(remove_baselines)
    skip_frames = header.ge_header.rdb.rdb_hdr_da_yres; %Changed to improve skip frames (was rdb_hdr_nframes)
    data(:, 1:skip_frames:nframes) = []; % Remove baselines (junk views)
    nframes  = length(data(:))/npts;
end
header.ge_header.rdb.rdb_hdr_user20 = nframes;

% Calculate trajectories
rad_traj  = calc_radial_traj_distance(header.ge_header);
primeplus = header.ge_header.rdb.rdb_hdr_user23;
frameSize = header.ge_header.rdb.rdb_hdr_frame_size;
header.MatrixSize = [frameSize frameSize frameSize];
traj = calc_archimedian_spiral_trajectories(nframes, primeplus, rad_traj)';

% Undo loopfactor from data and trajectories
% (not necessary, but nice if you want to plot fids)
loop_factor = header.ge_header.rdb.rdb_hdr_user10;
old_idx = 1:nframes;
new_idx = mod((old_idx-1)*loop_factor,nframes)+1;
data(:,old_idx) = data(:,new_idx);
traj = reshape(traj, [npts, nframes 3]);
traj(:,old_idx, :) = traj(:,new_idx,:);
traj = reshape(traj,[npts*nframes 3]);
clear old_idx new_idx;

% Calculate weights based on RF decay
n_dc_points = sum(rad_traj==0);
weights = repmat(abs(mean(data(1:n_dc_points,:))),[npts 1]);
weights = weights/max(weights(:));

data = data(:);
weights = weights(:);

end