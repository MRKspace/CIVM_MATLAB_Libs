%DEMO_GRIDDING   A demonstration of convolution based gridding reconstruction.
%   Note, you need to compile mex code before running the demo
%   mex -g grid_conv_mex.c. The compiling is only required once, then you
%   can comment out that line.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 2.0 $  $Date: December, 2012 $
%   $History: 2/7/2013 - Added Voronoi DCF
% clc; clear all; close all;

% % Recompile because its easy to forget...
% mex -g grid_conv_mex.c;
% mex -g ../DCF/sdc3_MAT.c;
% mex -g ../DCF/dcf_hitplane_mex.c;

% Read P-File header and data
disp('Reading P-file...');
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
undo_loopfactor = 0;    % No need to undo loopfactor, they are in order the same way the trajectories are
precision = 'int16';      % Can we read this from header? CSI extended mode uses int32
pfile_name   = filepath()

[data, traj, weights, header] = GE_Recon_Prep(pfile_name, floor(15), pfile_name);

% Typical Recon Params
kernel_width   = 1;
overgridfactor = 3;
kernel_lut_size = 2000;
header = header.ge_header;
num_points   = header.rdb.rdb_hdr_frame_size;
scale = 1;
output_dims  = uint32(round(scale*[num_points num_points num_points]));

% Calculate DCF - you only need to do this once, then you
% can reuse it as long as your trajectories are the same.
disp('Calculating DCF...');
dcf_type = 4; % 1=Analytical, 2=Hitplane, 3=Voronoi, 4=Itterative, 5=Voronoi+Itterative
im_sz_dcf = double(round(scale*num_points));
numIter = 5;
saveDCF_dir = '../DCF/precalcDCFvals/';
traj = 0.5*traj';
 dcf = calcDCF_Itterative(traj, overgridfactor,im_sz_dcf,numIter);

% dcf = calculateDCF(recon_data, header, dcf_type, overgridfactor, ...
%     kernel_width, output_dims, im_sz_dcf, numIter,saveDCF_dir);
clear dcf_type im_sz_dcf numIter saveDCF_dir;

% Apply DCF to data
data = [real(data)';
                   -imag(data)'];
data = data.*repmat(dcf,[2 1]);
% clear dcf;

%Calculate Gridding Kernel
disp('Calculating Kernel...');
kernel_width = kernel_width*overgridfactor; % Account overgridding
[kernel_vals]=KaiserBesselKernelGenerator(kernel_width, overgridfactor, ...
    kernel_lut_size);
clear kernel_lut_size;

%Regrid the fids
disp('Gridding...');
kspace_vol = grid_conv_mex(data, traj, ...
    kernel_width, kernel_vals, overgridfactor*output_dims);

% sz_ = size(kspace_vol);
% kspace_vol = reshape(kspace_vol(:).*dcf(:),sz_); 

% Calculate IFFT to get image volume
disp('Calculating IFFT...');
clear coords data kernel_vals kernel_width;
kspace_vol = fftshift(kspace_vol);
kspace_vol = ifftn(kspace_vol);     
kspace_vol = fftshift(kspace_vol);

% Crop out center of image to compensate for overgridding
% disp('Cropping out overgridding...');
% last = (overgridfactor-1)*output_dims/2;
% image_vol = kspace_vol(last(1)+1:last(1)+output_dims(1), ...
%     last(2)+1:last(2)+output_dims(2), ...
%     last(3)+1:last(3)+output_dims(3));
% clear kspace_vol last output_dims overgridfactor;

% Show the volume
figure();
imslice(abs(kspace_vol),'Magnitude Image Volume');

