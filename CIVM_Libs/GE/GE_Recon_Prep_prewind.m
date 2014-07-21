function [data, traj, weights, header] = GE_Recon_Prep_prewind(pfile_name, revision, rp_filename, offset, byte_order, precision)

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
load('toff_val.mat');
rad_traj  = linspace(0,1,npts)' - toff_val;%calc_radial_traj_distance_prewind(header.ge_header); 
primeplus = header.ge_header.rdb.rdb_hdr_user23;
frameSize = header.ge_header.rdb.rdb_hdr_frame_size;
header.MatrixSize = [frameSize frameSize frameSize];

per_nufft = header.ge_header.rdb.rdb_hdr_user32;
%     if ( per_nufft == 1)
         traj = calc_archimedian_spiral_trajectories(nframes, primeplus, rad_traj)';
%     end
%     if (per_nufft == 0)
%         traj = calc_golden_mean_trajectories(nframes, rad_traj)';
%         mess=sprintf('\nUsing Golden means\n');
%         disp(mess);
%     end

% Undo loopfactor from data and trajectories
% (not necessary, but nice if you want to plot fids)
loop_factor = header.ge_header.rdb.rdb_hdr_user10;
old_idx = 1:nframes;
new_idx = mod((old_idx-1)*loop_factor,nframes)+1;
data(:,old_idx) = data(:,new_idx);
traj = reshape(traj, [npts, nframes 3]);
traj(:,old_idx, :) = traj(:,new_idx,:);

% %% Option 1
% n_dc_points = sum(rad_traj==0);
% data = data(n_dc_points:npts,:);
% traj = traj(n_dc_points:npts,:,:);
% npts = npts - n_dc_points + 1;
% 
% % Calculate weights based on RF decay
% weights = repmat(abs(data(1,:)),[npts 1]);
% weights = weights/max(weights(:));

% dc_remove = find(rad_traj>0,1)-2;
% data(1:dc_remove,:)=[];
% traj(1:dc_remove,:,:)=[];

% Throw away data that is not on ramp
bad_pts = rad_traj <= 0;
data(bad_pts,:)=[];
traj(bad_pts,:,:)=[];
npts = size(data,1);
header.ge_header.rdb.rdb_hdr_frame_size = npts;%view points


% %% Option2 
% % Calculate weights based on RF decay
% n_dc_points = sum(rad_traj==0);
% weights = repmat(abs(mean(data(1:n_dc_points,:))),[npts 1]);
% % weights = repmat(abs(data(1,:)),[npts-n_dc_points+1 1]);
% weights = weights/max(weights(:));
weights = ones([npts nframes]);

% figure();
% surf(abs(data));
% shading interp;
% colormap(jet);
% xlabel('View Number');
% ylabel('Sample Number');
% zlabel('Magnitude');
% view([121 56])

% traj = reshape(traj,[(npts-n_dc_points+1)*nframes 3]);
sz = size(traj);
traj = reshape(traj,[sz(1)*sz(2) 3]);
clear old_idx new_idx;

data = data(:);
weights = weights(:);

if(any(abs(real(data(:)))>=32767) || any(abs(imag(data(:)))>=32767))
	h = warndlg('Maximum values exist - overrange was likely!','!! Warning !!');
	uiwait(h);
end

end
