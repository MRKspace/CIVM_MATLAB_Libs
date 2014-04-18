clc; close all;

load('mri'); % Matlab default
D = double(squeeze(D));

% Show volume before filtration
figure();
imslice(abs(D),'Unfiltered volume');

% Bilateral filter parameters
kernel_width = 3; % how far the filter filters each voxel
intensity_sigma = 10; % a rough measurement of intensity similarity
spatial_sigma = 1.5; % a rough measurement of spatial closeness

% Apply bilateral filter
b = BF_3D(abs(D),kernel_width,intensity_sigma,spatial_sigma);

% Show filtered volume
figure();
imslice(abs(b),'Filtered volume');
