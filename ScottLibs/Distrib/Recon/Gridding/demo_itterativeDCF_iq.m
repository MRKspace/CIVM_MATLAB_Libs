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
% pfile_name   = filepath('C:\Users\ScottHaileRobertson\Documents\MATLAB_libs\Datasets\Pfiles\P08192.7_lung_goldStd');
pfile_name   = filepath('C:\Users\ScottHaileRobertson\Documents\MATLAB_libs\Datasets\Pfiles\P08192.7_lung_goldStd')
% pfile_name = 'C:\Users\ScottHaileRobertson\Desktop\P15872.7';
header = ge_read_header(pfile_name, hdr_off, byte_order);


% Typical Recon Params
kernel_width   = 1;
overgridfactor = 3;
kernel_width = kernel_width*overgridfactor; % Account overgridding
kernel_lut_size = 800;
saveDCF_dir = '../DCF/precalcDCFvals/';
num_points   = header.rdb.rdb_hdr_frame_size;
scale = 1.6;
output_dims  = uint32(round(scale*[num_points num_points num_points]));

% Filter Params
fermi_scale    = 25;
fermi_width    = 0.72;

% Prepare the new file.
vidObj = VideoWriter('Recon_ItterativeDCF');
vidObj.FrameRate = 1;
open(vidObj);
fig = figure();

itterList = [0 1 2 3 4 5 6 8 10 12 14 16 18 20];
nitterList = length(itterList);
for i = 1:nitterList
    recon_data = Recon_Data();
    recon_data = recon_data.readPfileData(pfile_name,byte_order, precision,header);
    recon_data = recon_data.removeBaselines(header);
    
    rad_traj  = calc_radial_traj_distance(header);
    recon_data.Traj = calc_archimedian_spiral_trajectories(...
        recon_data.Nframes, header.rdb.rdb_hdr_user23, ...
        rad_traj);
    
    % Calculate DCF - you only need to do this once, then you
    % can reuse it as long as your trajectories are the same.
    disp('Calculating DCF...');
    dcf_type = 4; % 1=Analytical, 2=Hitplane, 3=Voronoi, 4=Itterative, 5=Voronoi+Itterative
    im_sz_dcf = double(round(scale*num_points));
    numIter = itterList(i)
    
    if(numIter ==0)
        dcf = ones(1,length(recon_data.Data(:)));
    else
        dcf = calculateDCF(recon_data, header, dcf_type, overgridfactor, ...
            kernel_width, output_dims, im_sz_dcf, numIter,saveDCF_dir);
    end
    
    % Apply DCF to data
    recon_data.Data = [real(recon_data.Data(:))';
        -imag(recon_data.Data(:))'];
    recon_data.Data = recon_data.Data.*repmat(dcf,[2 1]);
    clear dcf;
    
    %Calculate Gridding Kernel
    disp('Calculating Kernel...');
    [kernel_vals]=KaiserBesselKernelGenerator(kernel_width, overgridfactor, ...
        kernel_lut_size);
    
    % OPTIONAL Create fermi filter
    disp('Calculating filter...');
    % filter = FermiFilterGenerator(overgridfactor*output_dims,fermi_scale,fermi_width);
    filter = [];
    
    %Regrid the fids
    disp('Gridding...');
    tic
    kspace_vol = grid_conv_mex(recon_data.Data, recon_data.Traj, ...
        kernel_width, kernel_vals, overgridfactor*output_dims);
    recon_time = toc
    
    % sz_ = size(kspace_vol);
    % kspace_vol = reshape(kspace_vol(:).*dcf(:),sz_);
    
    % Apply Fermi filter
    if(~isempty(filter))
        disp('Filtering...');
        kspace_vol = kspace_vol .* filter;
    end
    
    % Calculate IFFT to get image volume
    disp('Calculating IFFT...');
    kspace_vol = fftshift(kspace_vol);
    kspace_vol = ifftn(kspace_vol);
    kspace_vol = fftshift(kspace_vol);
    
    % Crop out center of image to compensate for overgridding
    disp('Cropping out overgridding...');
    last = (overgridfactor-1)*output_dims/2;
    image_vol = kspace_vol(last(1)+1:last(1)+output_dims(1), ...
        last(2)+1:last(2)+output_dims(2), ...
        last(3)+1:last(3)+output_dims(3));
    clear kspace_vol last;
    
    % Show the volume
    imagesc(real(squeeze(image_vol(:,:,52))));
    colormap(gray);
    axis image;
    set(gca(),'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);
    title([num2str(numIter) ' Itterations']);
    writeVideo(vidObj,getframe(fig));
    clear image_vol; 
end

% Close the file.
close(vidObj);

% bin_mask = image_vol>0.0009;
% bin_mask = bwareaopen(bin_mask, 10,4);
%
% % Show the volume
% figure();
% showSlices(bin_mask,'Magnitude Image Volume');
%
% % Display the image volume
% figure();
% showSlices(angle(image_vol).*bin_mask,'Magnitude Image Volume');

% kernel_width = 4;
% intensity_sigma = 0.0003;
% spatial_sigma = 1.5;
% itter = 1;
% for i=1:itter
%     iteration = i
%     b = BF_3D(abs(image_vol),kernel_width,intensity_sigma,spatial_sigma);
% end
% figure();
% imslice(abs(b));