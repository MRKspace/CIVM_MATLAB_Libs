function [gas_fid_data, dissolved_fid_data, traj, gas_weights, ...
    dissolved_weights, header] = GE_Recon_Prep_Dual(headerfilename, revision,...
    rp_filename, offset, byte_order, precision)

if(nargin < 5)
    %Typically there is no offset to the header
    offset = 0;
    
    %Assume little endian format
    byte_order = 'ieee-le';
    
    % Can we read this from header? CSI extended mode uses int32
    precision = 'int16';
end

% Read the header for the correct rdb header revision
header.ge_header = ge_read_header(headerfilename, revision, offset, byte_order);

% Store important info from header
npts = header.ge_header.rdb.rdb_hdr_frame_size;%view points
nframes  = header.ge_header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;

fid = fopen(headerfilename, 'r', byte_order);
fseek(fid, header.ge_header.rdb.rdb_hdr_off_data, 'bof');
data = fread(fid,inf,precision);

% Data is complex (real and imaginery parts alternate)
data = complex(data(1:2:end),data(2:2:end));

% Separate baselines from raw data
nframes  = length(data(:))/npts;
data = reshape(data,npts,nframes);% Reshape into matrix

% Remove baselines
skip_frames = header.ge_header.rdb.rdb_hdr_da_yres; %Changed to improve skip frames (was rdb_hdr_nframes)
data(:, 1:skip_frames:nframes) = []; % Remove baselines (junk views)
nframes  = length(data(:))/npts;

% Remove extra junk view - not sure why this is necessary
data(:,1) = [];

% Split dissolved and gas data
dissolved_fid_data = data(:,1:2:end);
gas_fid_data = data(:,2:2:end);

% Calculate trajectories
nframes = length(dissolved_fid_data(:))/npts;
rad_traj  = calc_radial_traj_distance(header.ge_header);
primeplus = header.ge_header.rdb.rdb_hdr_user23;
header.MatrixSize = [npts npts npts];
traj = calc_archimedian_spiral_trajectories(nframes, primeplus, rad_traj)';

% Undo loopfactor from data and trajectories
% (not necessary, but nice if you want to plot fids)
loop_factor = header.ge_header.rdb.rdb_hdr_user10;
old_idx = 1:nframes;
new_idx = mod((old_idx-1)*loop_factor,nframes)+1;
dissolved_fid_data(:,old_idx) = dissolved_fid_data(:,new_idx);
gas_fid_data(:,old_idx) = gas_fid_data(:,new_idx);
traj = reshape(traj, [npts, nframes 3]);
traj(:,old_idx, :) = traj(:,new_idx,:);
clear old_idx new_idx;

% Calculate weights based on RF decay
n_dc_points = sum(rad_traj==0);
gas_weights = repmat(abs(mean(gas_fid_data(1:n_dc_points,:))),[npts 1]);
gas_weights = gas_weights/max(gas_weights(:));
dissolved_weights = repmat(abs(mean(dissolved_fid_data(1:n_dc_points,:))),[npts 1]);
dissolved_weights = dissolved_weights/max(dissolved_weights(:));

% Override trajectories
traj = reshape(traj,[npts*nframes 3]);
dissolved_fid_data = reshape(dissolved_fid_data,[npts*nframes 1]);
gas_fid_data = reshape(gas_fid_data,[npts*nframes 1]);

end