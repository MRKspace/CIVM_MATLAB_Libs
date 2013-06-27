% load('Wed/vol_pre.mat');
% load('mask_pre.mat');
% load('susc_pre.mat');
% vol = vol_pre;

% load('Wed/vol_post.mat');
% load('mask_post.mat');
% load('susc_post.mat');
% vol = vol_post;

load('Wed/vol_postpost.mat');
load('mask_postpost.mat');
% % load('susc_postpost.mat');
vol = vol_postpost;

% figure();imslice(abs(vol),'Ventilation'); colorbar();
 figure();imagesc(flipud(abs(vol(62:205,50:176,155))));colormap(gray); axis image; colorbar(); set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);title('Ventilation');

phase = angle(vol);
 figure();imagesc(flipud(phase(62:205,50:176,155)));colormap(gray); axis image; colorbar(); set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);title('Raw Phase');
% figure();imslice(phase,'Raw Phase'); colorbar();
% figure();imslice(phase.*mask,'Phase'); colorbar();
% figure();imslice(unwrap(phase).*mask,'Phase Unwrapped'); colorbar();
% figure();imslice(X,'Susceptibility'); colorbar();
% figure();imslice(abs(vol_pre),'Pre MION');

% % Bilateral filter data
% a = abs(vol_postpost);
% a = a - min(a(:));
% a = a / max(a(:));
% b = a;
% % b = a(120:140,120:140,120:140);
% % b = a(61:205,50:176,92:205);
% kernel_width = 4;
% intensity_sigma = 0.1;
% spatial_sigma = 1.5;
% 
% bf_im = BF_3D_fast(b,kernel_width,intensity_sigma,spatial_sigma);

% 
% % imslice(real(mask_vol.*image_vol));
% mask = bf_im>0.08; %Pre
% mask = bf_im>0.095; %Post

% Calculate phase
phase_im = angle(vol);
% imslice(mask.*phase_im);
% phase_im2 = angle(vol_postpost);
% phase_im = phase_im1;%-phase_im1;

% Unwrap phase
phase_unwrapped = unwrap_phase_laplacian(phase_im);

% spatial_res = [1 1 1];
% padsz = [20 20 20];
% figure();imslice(phase_unwrapped, 'Unwrapped Phase'); colorbar();
 figure();imagesc(flipud(phase_unwrapped(62:205,50:176,155)));colormap(gray); axis image; colorbar(); set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);title('Unwrapped Phase');
% Filter out slowly varying phase
sigma = 0.125;
filt_phase = homodyneFilter(phase_unwrapped, sigma);
% figure();imslice(filt_phase, 'Homodyne Filtered Phase'); colorbar();
 figure();imagesc(flipud(filt_phase(62:205,50:176,155)));colormap(gray); axis image; colorbar(); set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);title('Homodyne Filtered Phase');

% Create lung mask
% mask_vol = ones(size(phase_im));
% mask_vol = filt_pre>0.04;
% mask_vol = bwareaopen(mask_vol,60,6); % Remove noise

% mask_vol = ~bwareaopen(~mask_vol,60,4); % Remove holes
% strel_ = strel('disk', 1, 4)
% mask_vol = imdilate(mask_vol, strel_, 'same');

parameter.TE = 4; %ms
parameter.B0 = 1.5; %; % T 
parameter.FOV = [30 30 30]; % mm
gamma_bar = 638662330;% %MHz/T
parameter.gamma = gamma_bar*2*pi; %rad/(sec*T)
parameter.H = [0 0 1]; % e.g. [0 0 1] - Tells which dimmension is b0


% Calculate Susceptibility Image
[X,coeff] = Calc_AMS_LSQR(filt_phase,mask,parameter);
% [X,coeff] = Calc_AMS_LSQR(phase_unwrapped,mask,parameter);

% figure(); imslice(X, 'Susceptibility'); colorbar();
 figure();imagesc(flipud(X(62:205,50:176,155)));colormap(gray); axis image; colorbar(); set(gca,'XTickLabel',[],'YTickLabel',[],'XTick',[],'YTick',[]);title('Susceptibility');