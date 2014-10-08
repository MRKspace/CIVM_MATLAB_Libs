clc; close all;

load('mri'); % Matlab default
D = double(squeeze(D));

% Show volume before filtration
figure();
imslice(abs(D),'Unfiltered volume');

% Bilateral filter parameters
kernel_width = 5; % how far the filter filters each voxel
% intensity_sigma = 0.003; % a rough measurement of intensity similarity
intensity_sigma = 0.002; % a rough measurement of intensity similarity
spatial_sigma = 1.25; % a rough measurement of spatial closeness

% Apply bilateral filter
c = BF_3D(abs(b),kernel_width,intensity_sigma,spatial_sigma);

% Show filtered volume
figure();
imslice(abs(c),'Filtered volume');
