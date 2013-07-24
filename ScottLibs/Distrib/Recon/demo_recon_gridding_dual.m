%DEMO_GRIDDING_DUAL   A demonstration of convolution based gridding 
% reconstruction for a dual-excitation pfile..
%   Note, you need to compile mex code before running the demo
%   mex -g grid_conv_mex.c. The compiling is only required once, then you
%   can comment out that line.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: July 24, 2013 $
% clc; clear all; close all;

% % Recompile because its easy to forget...
disp('Compiling gridding code. You should only need to do this once, or when the code changes.');
mex -g ./Gridding/grid_conv_mex.c;
mex -g ./DCF/sdc3_MAT.c;
mex -g ./DCF/dcf_hitplane_mex.c;

% Parameters that almost never change.
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
precision = 'int16';      % Can we read this from header? CSI extended mode uses int32

% Reconstruction options
options.headerfilename = filepath();
kernel_width   = 1;
overgridfactor = 3;
kernel_lut_size = 5000;
scale = 2;
dcf_type = 4; % 1=Analytical, 2=Hitplane, 3=Voronoi, 4=Itterative, 5=Voronoi+Itterative
numIter = 25;
saveDCF_dir = '../DCF/precalcDCFvals/';

% Read header
header = ge_read_header(options.headerfilename, hdr_off, byte_order);

% Store important info from header
npts = header.rdb.rdb_hdr_frame_size;%view points
nframes  = header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;


fid = fopen(options.headerfilename, 'r', byte_order);
fseek(fid, header.rdb.rdb_hdr_off_data, 'bof');
data = fread(fid,inf,precision);

% Data is complex (real and imaginery parts alternate)
data = complex(data(1:2:end),data(2:2:end));

% Separate baselines from raw data
nframes  = length(data(:))/npts;
data = reshape(data,npts,nframes);% Reshape into matrix

% Remove baselines
skip_frames = header.rdb.rdb_hdr_da_yres; %Changed to improve skip frames (was rdb_hdr_nframes)
data(:, 1:skip_frames:nframes) = []; % Remove baselines (junk views)
nframes  = length(data(:))/npts;

% Remove extra junk view - not sure why this is necessary
data(:,1) = [];

% Split dissolved and gas data
dissolved_fid_data = data(:,1:2:end);
gas_fid_data = data(:,2:2:end);

% Calculate trajectories
nframes = length(dissolved_fid_data(:))/npts;
rad_traj  = calc_radial_traj_distance(header);
primeplus = header.rdb.rdb_hdr_user23;
traj = calc_archimedian_spiral_trajectories(nframes, primeplus, rad_traj)';

% Undo loopfactor from data and trajectories
% (not necessary, but nice if you want to plot fids)
loop_factor = header.rdb.rdb_hdr_user10;
old_idx = 1:nframes;
new_idx = mod((old_idx-1)*loop_factor,nframes)+1;
dissolved_fid_data(:,old_idx) = dissolved_fid_data(:,new_idx);
gas_fid_data(:,old_idx) = gas_fid_data(:,new_idx);
traj = reshape(traj, [npts, nframes 3]);
traj(:,old_idx, :) = traj(:,new_idx,:);
% traj = reshape(traj,[npts*nframes 3]);
clear old_idx new_idx;

% Calculate weights based on RF decay
n_dc_points = sum(rad_traj==0);
gas_weights = repmat(abs(mean(gas_fid_data(1:n_dc_points,:))),[npts 1]);
gas_weights = gas_weights/max(gas_weights(:));
dissolved_weights = repmat(abs(mean(dissolved_fid_data(1:n_dc_points,:))),[npts 1]);
dissolved_weights = dissolved_weights/max(dissolved_weights(:));

min_gas_weight = min(gas_weights(:))
max_gas_weight = max(gas_weights(:))
min_dissolved_weight = min(dissolved_weights(:))
max_dissolved_weight = max(dissolved_weights(:))

% Override trajectories
traj = reshape(traj,[npts*nframes 3]);

% Calculate DCF - you only need to do this once, then you
% can reuse it as long as your trajectories are the same.
disp('Calculating DCF...');
num_points   = header.rdb.rdb_hdr_frame_size;
output_dims  = uint32(round(scale*[num_points num_points num_points]));
im_sz_dcf = double(round(scale*num_points));
traj = traj'/scale;
while(any(traj(:)>0.5))
    addIdx = traj(:)>0.5;
    traj(addIdx) = traj(addIdx) - 1;
end
while(any(traj(:)<-0.5))
    subIdx = traj(:)<-0.5;
    traj(subIdx) = traj(subIdx) + 1;
end
 dcf = calcDCF_Itterative(traj, overgridfactor,im_sz_dcf,numIter);

% dcf = calculateDCF(recon_data, header, dcf_type, overgridfactor, ...
%     kernel_width, output_dims, im_sz_dcf, numIter,saveDCF_dir);
clear dcf_type im_sz_dcf numIter saveDCF_dir;

%Calculate Gridding Kernel
disp('Calculating Kernel...');
kernel_width = kernel_width*overgridfactor; % Account overgridding
[kernel_vals]=KaiserBesselKernelGenerator(kernel_width, overgridfactor, ...
    kernel_lut_size);
clear kernel_lut_size;

% Reconstruct gas phase data
disp('Gridding gas phase...');
options.data = gas_fid_data(:);
options.data = [real(options.data)'; -imag(options.data)'].*repmat(dcf,[2 1]); % apply dcf
kspace_vol = grid_conv_mex(options.data, traj, ...
    kernel_width, kernel_vals, overgridfactor*output_dims);
% Calculate IFFT to get image volume
disp('Calculating IFFT...');
kspace_vol = fftshift(kspace_vol);
kspace_vol = ifftn(kspace_vol);     
kspace_vol = fftshift(kspace_vol);
% Crop out center of image to compensate for overgridding
% disp('Cropping out overgridding...');
last = (overgridfactor-1)*output_dims/2;
recon_gas = kspace_vol(last(1)+1:last(1)+output_dims(1), ...
    last(2)+1:last(2)+output_dims(2), ...
    last(3)+1:last(3)+output_dims(3));
clear kspace_vol last;
% options.weights = reshape(gas_weights,[npts*nframes 1]);

% Filter
recon_gas = FermiFilter(recon_gas,0.1/scale, 0.85/scale);

%Show output
figure();
imslice(abs(recon_gas),'Gas Phase');

% Reconstruct dissolved phase data
disp('Gridding Dissolved phase...');
options.data = dissolved_fid_data(:);
options.data = [real(options.data)'; -imag(options.data)'].*repmat(dcf,[2 1]); % apply dcf
kspace_vol = grid_conv_mex(options.data, traj, ...
    kernel_width, kernel_vals, overgridfactor*output_dims);
% Calculate IFFT to get image volume
disp('Calculating IFFT...');
kspace_vol = fftshift(kspace_vol);
kspace_vol = ifftn(kspace_vol);     
kspace_vol = fftshift(kspace_vol);
% Crop out center of image to compensate for overgridding
% disp('Cropping out overgridding...');
last = (overgridfactor-1)*output_dims/2;
recon_dissolved = kspace_vol(last(1)+1:last(1)+output_dims(1), ...
    last(2)+1:last(2)+output_dims(2), ...
    last(3)+1:last(3)+output_dims(3));
clear kspace_vol last;
% options.weights = reshape(gas_weights,[npts*nframes 1]);

% Filter
recon_dissolved = FermiFilter(recon_dissolved,0.1/scale, 0.85/scale);

%Show output
figure();
imslice(abs(recon_dissolved),'Dissolved Phase');

% Save gas volume
nii = make_nii(abs(recon_gas));
save_nii(nii, 'gas.nii', 16);

% Save dissolved volume
nii = make_nii(abs(recon_dissolved));
save_nii(nii, 'dissolved.nii', 16);