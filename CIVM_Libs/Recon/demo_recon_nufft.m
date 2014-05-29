% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% Start with a clean slate
clc; clear all; close all; fclose all;

% Define reconstruction options
if(exist('~/.matlab_recon_prefs.mat'))
	load('~/.matlab_recon_prefs.mat');
end

% Get pfile
if(exist('pfile_root_dir','var'))
	headerfilename = filepath(pfile_root_dir)
else
	headerfilename = filepath()
end
datafilename = '';
overgridfactor = 2;
nNeighbors = 3;
scale = 1*[1 1 1]% Scales the matrix dimmensions
dcf_iter = 25;
useAllPts = 1;

% Read in the file and prepare for generic reconstruction
[revision, logo] = ge_read_rdb_rev_and_logo(headerfilename);
[data, traj, weights, header] = GE_Recon_Prep(headerfilename, ...
	floor(revision), datafilename);
% data = data./weights;

title_vals = {
	[headerfilename ]
	['te=' num2str(header.ge_header.image.te) ]
	['tr=' num2str(header.ge_header.image.tr)]
	['opflip=' num2str(header.ge_header.rdb.rdb_hdr_user0) ]
	['lopflip=' num2str(header.ge_header.rdb.rdb_hdr_user36) ]
	['pwrampa='  num2str(header.ge_header.rdb.rdb_hdr_user1) ]
	['pwrampd='  num2str(header.ge_header.rdb.rdb_hdr_user38) ]
	['nframes='  num2str(header.ge_header.rdb.rdb_hdr_user20) ]
	['loopfactor=' num2str(header.ge_header.rdb.rdb_hdr_user10) ]
	['opslthick=' num2str(header.ge_header.rdb.rdb_hdr_user11) ]
	['oprbw=' num2str(header.ge_header.rdb.rdb_hdr_user12) ]
	['loprewind=' num2str(header.ge_header.rdb.rdb_hdr_user15) ]
	['fov=' num2str(header.ge_header.image.dfov) ]
	['psd_toff2=' num2str(header.ge_header.rdb.rdb_hdr_user22) ]
	['ia_gxw=' num2str(header.ge_header.rdb.rdb_hdr_user27) ]
	['ia_gy1=' num2str(header.ge_header.rdb.rdb_hdr_user28) ]
	['ia_gzw=' num2str(header.ge_header.rdb.rdb_hdr_user29) ]
	['per_nufft=' num2str(header.ge_header.rdb.rdb_hdr_user32) ]
	['sinct=' num2str(header.ge_header.rdb.rdb_hdr_user32) ]
	['noslice=' num2str(header.ge_header.rdb.rdb_hdr_user34) ]
	['rephasertime=' num2str(header.ge_header.rdb.rdb_hdr_user35) ]
	['dummy=' num2str(header.ge_header.rdb.rdb_hdr_user37) ]
	['hardpulse=' num2str(header.ge_header.rdb.rdb_hdr_user39) ]
	['ramp_ratio=' num2str(header.ge_header.rdb.rdb_hdr_user40) ]
	['extra_toff_points=' num2str(header.ge_header.rdb.rdb_hdr_user41) ]
	['nramp=' num2str(header.ge_header.rdb.rdb_hdr_user42) ]
	['tdaq_filt=' num2str(header.ge_header.rdb.rdb_hdr_user43) ]
	['npts_filt=' num2str(header.ge_header.rdb.rdb_hdr_user44) ]
	['tsp_filt=' num2str(header.ge_header.rdb.rdb_hdr_user45) ]
	};
ntitStr = length(title_vals);
title_str = title_vals{1};
for k = 1:ntitStr
	disp(title_vals{k});
end

inv_scale = 1./scale;
N = header.MatrixSize;
for i=1:length(N)
	N(i) = max(floor(N(i)*scale(i)),1);
end
if(useAllPts)
	traj = 0.5*traj;
	N = 2*N;
end
for i=1:length(N)
	traj(:,i) = traj(:,i)*inv_scale(i);
end
J = [nNeighbors nNeighbors nNeighbors];
K = ceil(N*overgridfactor);


%% Throw away data outside the BW
throw_away = find((traj(:,1)>0.5) + (traj(:,2)>0.5) + (traj(:,3)>0.5) + ...
	(traj(:,1)<-0.5) + (traj(:,2)<-0.5) + (traj(:,3)<-0.5));
traj(throw_away(:),:)=[];
data(throw_away(:))=[];
weights(throw_away(:))=[];

% Create reconstruction object
reconObj = ConjugatePhaseReconstructionObject(traj, N, J, K, dcf_iter);

% Reconstruct data
recon_vol = reconObj.reconstruct(data);
phase_vol = unwrap_phase_laplacian(angle(recon_vol));
% fft_vol = fftshift(fftn(recon_vol));

%Show output
figure();
imslice(abs(recon_vol),'Magnitude');
% figure();
% imslice(phase_vol,'Phase');
% figure();
% imslice(abs(fft_vol),'Magnitude FFT');

% % Bilateral filter parameters
% kernel_width = 4; % how far the filter filters each voxel
% intensity_sigma = 0.75E4; % a rough measurement of intensity similarity
% spatial_sigma = 1.25; % a rough measurement of spatial closeness
%
% % Apply bilateral filter
% % sub_vol = recon_vol(85:180,85:180,90:154);
% recon_vol2 = BF_3D(abs(recon_vol),kernel_width,intensity_sigma,spatial_sigma);
% figure();
% imslice(recon_vol2,'Filtered');


% base = 'test';
% 
% % % Save volume
% nii = make_nii(abs(recon_vol));
% save_nii(nii, [base '_mag.nii'], 16);
% nii = make_nii(abs(phase_vol));
% save_nii(nii, [base '_phase.nii'], 16);
% nii = make_nii(fft_vol);
% save_nii(nii, [base '_fft.nii'], 16);
