% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% Start with a clean slate
clc; clear all; close all; fclose all;

% Define reconstruction options
if(exist('~/.matlab_recon_prefs.mat'))
	load('~/.matlab_recon_prefs.mat');
end

% % Get pfile
% if(exist('pfile_root_dir','var'))
% 	headerfilename = filepath(pfile_root_dir)
% else
% 	headerfilename = filepath()
% end

headerfilename = filepath('/home/scott/Public/pfiles/demo/P16384.7_lung')
% headerfilename = filepath('/home/scott/Public/pfiles/20140614/');
datafilename = '';
overgridfactor = 3;
kernel_width   = 3;
nNeighbors = 3;
scale = 1*[1 1 1]% Scales the matrix dimmensions
dcf_iter = 50;
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
	['rewind_on=' num2str(header.ge_header.rdb.rdb_hdr_user15) ]
	['crush_on=' num2str(header.ge_header.rdb.rdb_hdr_user14) ]
	['crush_scale=' num2str(header.ge_header.rdb.rdb_hdr_user19) ]
	['spgr_flag=' num2str(header.ge_header.rdb.rdb_hdr_user4) ]
	['phase_offset=' num2str(header.ge_header.rdb.rdb_hdr_user25) ]
	['phase_offset_r=' num2str(header.ge_header.rdb.rdb_hdr_user26) ]
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
	['TG=' num2str(header.ge_header.rdb.rdb_hdr_ps_mps_tg) ]
	['R1=' num2str(header.ge_header.rdb.rdb_hdr_ps_mps_r1) ]
	['R2=' num2str(header.ge_header.rdb.rdb_hdr_ps_mps_r2) ]
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
% 	overgridfactor = 2*overgridfactor;
end
for i=1:length(N)
	traj(:,i) = traj(:,i)*inv_scale(i);
end
J = [nNeighbors nNeighbors nNeighbors];
K = ceil(N*overgridfactor);

% Calculate distances
[sample_idx,voxel_idx,distances] = ...
	sparse_gridding_distance_mex(traj',kernel_width,uint32(K'));

% Remove nonzero entries
nonzero_idx = (sample_idx ~= 0);
sample_idx = sample_idx(nonzero_idx);
voxel_idx = voxel_idx(nonzero_idx);
distances = distances(nonzero_idx);

% Show that gridding is reasonable
figure();
subplot(3,1,1);
plot(sample_idx)
subplot(3,1,2);
plot(voxel_idx)
subplot(3,1,3);
plot(distances)

% Calculate kernel values
[distances]=KaiserBesselKernel(kernel_width, overgridfactor, distances);

% Create sparse system matrix;
A = sparse(sample_idx,voxel_idx,distances,size(data,1),prod(K));

% Perform DCF
psf_samples = ones(K); 
dcf = 1./(A*psf_samples(:));
for iDcf = 1:dcf_iter
	disp(['DCF itteration ' num2str(iDcf)]);
	dcf = dcf./(A*(A'*dcf));
end
clear psf_samples;

% dcf = reshape(dcf,[64 4601]);
% figure();
% plot(dcf);


% Perform gridding
recon_vol = A' * (dcf .* data);
recon_vol = reshape(recon_vol,K);
imslice(log(abs(recon_vol)));

im_vol = fftshift(ifftn(fftshift(recon_vol)));
imslice(abs(im_vol));

