% Start with a clean slate
clc; clear all; close all;

options.headerfilename = filepath();
% options.datafilename = filepath();
options.datafilename = '';
options.overgridfactor = 2;
options.nNeighbors = 3;
options.scale = 1;
options.dcf_iter = 25;
options.exact = 0; % CAUTION - this will make recon EXTREMELY slow!
options.exact_dct_iter = 0;

tic;
[recon_vol, header, reconObj] = Recon_Noncartesian(options);
initial_recon_time = toc

% Filter
% recon_vol = FermiFilter(recon_vol,0.1/options.scale, 0.85/options.scale);

%Show output
figure();
imslice(abs(recon_vol),'Reconstruction');

% % Now add the reconObject and run again... this will show how much time it

% Save volume
nii = make_nii(abs(recon_vol));
save_nii(nii, 'recon_vol.nii', 32);

