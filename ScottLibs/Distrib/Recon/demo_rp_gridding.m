%DEMO_GRIDDING   A demonstration of convolution based gridding reconstruction.
%   Note, you need to compile mex code before running the demo
%   mex -g grid_conv_mex.c. The compiling is only required once, then you
%   can comment out that line.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 2.0 $  $Date: December, 2012 $
%   $History: 2/7/2013 - Added Voronoi DCF
clc; clear all; close all;

% Recompile because its easy to forget...
mex -g grid_conv_mex.c;
mex -g ../DCF/sdc3_MAT.c;
mex -g ../DCF/dcf_hitplane_mex.c;

% Read P-File header and data
disp('Reading P-file...');
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
undo_loopfactor = 0;    % No need to undo loopfactor, they are in order the same way the trajectories are
precision = 'int16';      % Can we read this from header? CSI extended mode uses int32
pfile_name   = filepath()
header = ge_read_header(pfile_name, hdr_off, byte_order);

pfile_name   = filepath()

recon_data = Recon_Data();
recon_data = recon_data.readPfileData(pfile_name,byte_order, precision,header);
% recon_data = recon_data.removeBaselines(header);

rad_traj  = calc_radial_traj_distance(header);
recon_data.Traj = calc_archimedian_s piral_trajectories(...
    recon_data.Nframes, header.rdb.rdb_hdr_user23, ...
    rad_traj);

% Typical Recon Params
kernel_width   = 1;
overgridfactor = 2;
kernel_lut_size = 800;
num_points   = header.rdb.rdb_hdr_frame_size;
scale = 1.6;
output_dims  = uint32(round(scale*[num_points num_points num_points]));

% Filter Params
fermi_scale    = 25;
fermi_width    = 0.72;

% Calculate DCF - you only need to do this once, then you
% can reuse it as long as your trajectories are the same.
disp('Calculating DCF...');
dcf_type = 4; % 1=Analytical, 2=Hitplane, 3=Voronoi, 4=Itterative, 5=Voronoi+Itterative
im_sz_dcf = double(round(scale*num_points));
numIter = 30;
saveDCF_dir = '../DCF/precalcDCFvals/';
dcf = calculateDCF(recon_data, header, dcf_type, overgridfactor, ...
    kernel_width, output_dims, im_sz_dcf, numIter,saveDCF_dir);
clear dcf_type im_sz_dcf numIter saveDCF_dir;

% Apply DCF to data
recon_data.Data = [real(recon_data.Data(:))';
                   -imag(recon_data.Data(:))'];
recon_data.Data = recon_data.Data.*repmat(dcf,[2 1]);
clear dcf;

%Calculate Gridding Kernel
disp('Calculating Kernel...');
kernel_width = kernel_width*overgridfactor; % Account overgridding
[kernel_vals]=KaiserBesselKernelGenerator(kernel_width, overgridfactor, ...
    kernel_lut_size);
clear kernel_lut_size;

% OPTIONAL Create fermi filter
disp('Calculating filter...');
filter = FermiFilterGenerator(overgridfactor*output_dims,fermi_scale,fermi_width);
% filter = [];

%Regrid the fids
disp('Gridding...');
kspace_vol = grid_conv_mex(recon_data.Data, recon_data.Traj, ...
    kernel_width, kernel_vals, overgridfactor*output_dims);

% Apply Fermi filter
if(~isempty(filter))
    disp('Filtering...');
    kspace_vol = kspace_vol .* filter;
end

% Calculate IFFT to get image volume
disp('Calculating IFFT...');
clear coords data kernel_vals kernel_width;
kspace_vol = fftshift(kspace_vol);
kspace_vol = ifftn(kspace_vol);     
kspace_vol = fftshift(kspace_vol);

% Crop out center of image to compensate for overgridding
disp('Cropping out overgridding...');
last = (overgridfactor-1)*output_dims/2;
image_vol = kspace_vol(last(1)+1:last(1)+output_dims(1), ...
    last(2)+1:last(2)+output_dims(2), ...
    last(3)+1:last(3)+output_dims(3));
clear kspace_vol last output_dims overgridfactor;

% Show the volume
figure();
showSlices(abs(image_vol),'Magnitude Image Volume');

% Save volume
nii = make_nii(abs(image_vol));
save_nii(nii, 'recon_vol.nii', 16);