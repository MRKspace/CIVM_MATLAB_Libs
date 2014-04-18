%RECON_GRIDCONV   Convolution based gridding reconstruction.
%   RECON_GRIDCONV(recon_data,kernel_width,overgridfactor,fermi_scale,
%   fermi_width) reconstructs an image from the given recon data using a 
%   Kaiser-Bessel kernel. kernel_width defines the width of the kernel. The
%   image can be overgridded to reduce aliasing artifacts (3 is a standard 
%   overgridfactor). Increasing the overgrid factor improves image quality, 
%   but the memory requirement increases with the cube (third power) of 
%   overgridfactor. The incremental benefit to aliasing artifacts decreases
%   with increased overgridfactor. A fermi filter is then applied to the
%   output image with a width and scale defined by fermi_width and 
%   fermi_scale. The image domain volume and frequency domain volume are 
%   returned.
%
%   See also GE_READ_PFILE, CALC_RADIAL_TRAJ_DISTANCE,
%   CALC_ARCHIMEDIAN_SPIRAL_TRAJECTORIES, KAISERBESSELKERNELGENERATOR,
%   FERMIFILTERGENERATOR, GRID_CONV_MEX.C.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/07/19 $
function [output_vol] = Recon_GridConv(recon_data, kernel_width, overgridfactor, output_dims, varargin)


disp('Preparing for gridding...');

%Check if filter given
if(nargin > 3)
    filter = varargin{1};
else
    filter = [];
end

%Calculate Gridding Kernel
kernel_width = kernel_width*overgridfactor; % Account overgridding
[kernel_vals]=KaiserBesselKernelGenerator(kernel_width,overgridfactor, 800);

% Get data into recon format
fid_data.Data = [real(fid_data.Data(:)');
    imag(fid_data.Data(:)')];

%Regrid the fids
disp('Gridding...');
output_vol = grid_conv_mex(fid_data.Data, fid_data.Traj, ...
    kernel_width, kernel_vals, overgridfactor*output_dims);

% Apply Fermi filter
if(~isempty(filter))
    disp('Filtering...');
    output_vol = output_vol .* filter;
end

% Calculate IFFT to get image volume
disp('Calculating IFFT...');
output_vol = fftshift(ifftn(fftshift(output_vol)));

% Crop out center of image to compensate for overgridding
last = (overgridfactor-1)*output_dims(1)/2;
output_vol = output_vol(last+1:last+output_dims(1), ...
    last+1:last+output_dims(2), ...
    last+1:last+output_dims(3));

disp(sprintf('Recon time=%d seconds.',toc));

% Free up some memory
clear header kernel_vals fermi_filter;