clc; close all;
load('recon_vol.mat');

a = image_vol;

kernel_width = 4;
intensity_sigma = 0.0002;
spatial_sigma = 1.5;


% filt =  fspecial('gaussian', [kernel_width kernel_width], spatial_sigma);
% b = imfilter(squeeze(image_vol(:,:,52)),filt,'replicate','same');


b = BF_3D(abs(a),kernel_width,intensity_sigma,spatial_sigma);

figure();
imslice(abs(a));

% load('bf_vol.mat');
% imslice(abs(b));