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

data_bad = data;

% Overide calculated trajectories with measured
% npts = header.ge_header.rdb.rdb_hdr_frame_size;%view points
% nframes  = header.ge_header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;
% traj2 = traj;
% load('/home/scott/Desktop/gradscale_files/traj_golden_4795.mat');
% traj = reshape(traj,[npts size(traj,1)/npts 3]);
% traj = traj(:,1:nframes,:);
% traj2 = reshape(traj2,[npts size(traj2,1)/npts 3]);
% traj = reshape(traj,[npts*nframes 3]);

% data = reshape(data,[npts nframes]);
% grad_vals = -gradient(traj(1:npts,1,3));
% grad_vals = grad_vals/grad_vals(end);
% ideal_grad = -gradient(traj2(1:npts,1,3));
% ideal_grad = ideal_grad/ideal_grad(end);
% grad_fin = [grad_vals ideal_grad];
% figure();
% hold on;
% [AX,H1,H2] = plotyy(1:npts,mean(abs(data),2),[1:npts; 1:npts]',grad_fin);
% hold off
% xlabel('Sample Point');
% set(get(AX(1),'Ylabel'),'String','Average Magnitude')
% set(get(AX(2),'Ylabel'),'String','Normalized Gradeint Amplitude')
% data = reshape(data,[npts*nframes 1]);
%
%
% traj = reshape(traj,[npts*nframes 3]);
%
% figure()
% subplot(1,3,1)
% hold on;
% plot(traj2(1:128,1),'-r');
% plot(traj(1:128,1),'-b');untitled.jpg
% legend('Ideal','Measured');
%
% subplot(1,3,2)
% hold on;
% plot(traj2(1:128,2),'-r');
% plot(traj(1:128,2),'-b');
%
% subplot(1,3,3)

% %% Plot traj and gradients
% figure();
% for i = 1:10
% subplot(1,2,1)
% plot(traj2(1:128,i,1),'-r');
% hold on;
% plot(traj(1:128,i,1),'--r');
% plot(traj2(1:128,i,2),'-b');
% plot(traj(1:128,i,2),'--b');
% plot(traj2(1:128,i,3),'-g');
% plot(traj(1:128,i,3),'--g');
% hold off;
%
% subplot(1,2,2)
% plot(gradient(traj2(1:128,i,1)),'-r');
% hold on;
% plot(gradient(traj(1:128,i,1)),'--r');
% plot(gradient(traj2(1:128,i,2)),'-b');
% plot(gradient(traj(1:128,i,2)),'--b');
% plot(gradient(traj2(1:128,i,3)),'-g');
% plot(gradient(traj(1:128,i,3)),'--g');
% hold off;
% pause
% end
% temper = 1;
% traj = reshape(traj,[npts*nframes 3]);
% traj2 = traj2(:,1:nframes,:);


% npts = header.ge_header.rdb.rdb_hdr_frame_size;%view points
% nframes  = header.ge_header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;
% data = reshape(data,[npts nframes]);
% traj = res% npts = header.ge_header.rdb.rdb_hdr_frame_size;%view points
% nframes  = header.ge_header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;
% traj2 = traj;
% load('/home/scott/Desktop/gradscale_files/traj_golden_4795.mat');
% traj = reshape(traj,[npts size(traj,1)/npts 3]);
% traj = traj(:,1:nframes,:);
% traj = reshape(traj,[npts*nframes 3]);npts = header.ge_header.rdb.rdb_hdr_frame_size;%view points

% nframes  = header.ge_header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;
% traj2 = traj;
% load('/home/scott/Desktop/gradscale_files/traj_golden_4795.mat');
% traj = reshape(traj,[npts size(traj,1)/npts 3]);
% traj = traj(:,1:nframes,:);
% traj = reshape(traj,[npts*nframes 3]);

% hape(traj,[npts nframes 3]);
% bad_frames = any(abs(data(17:end,:))>400);
% n_badframes = sum(bad_frames)
% data(:,bad_frames) = [];
% traj(:,bad_frames,:) = [];
%
%
% last_pt = 58;
% data = data(1:last_pt,:);
% traj = traj(1:last_pt,:,:);
%
% figure();
% surf(abs(data));
% shading interp

%
% [npts nframes] = size(data);
% data = reshape(data,[(last_pt)*(nframes-n_badframes) 1]);
% traj = reshape(traj,[(last_pt)*(nframes-n_badframes) 3]);


% data = reshape(data,[npts nframes]);
% traj = reshape(traj,[npts nframes 3]);
% traj2 = reshape(traj2,[npts nframes 3]);
% for i=1:4795
% 	figure(1);
% 	subplot(3,1,1);
% 	plot(traj2(:,i),'-b');
% 	hold on;
% 	plot(traj(:,i),'-r');
% 	hold off;
%
% 		subplot(3,1,2);
% 	plot(traj2(:,i),'-b');
% 	hold on;
% 	plot(traj(:,i),'-r');
% 	hold off;
%
% 		subplot(3,1,3);
% 	plot(traj2(:,i),'-b');
% 	hold on;
% 	plot(traj(:,i),'-r');
% 	hold off;
% 	drawnow;
% 	pause;
% end

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

% first_frames = 1500;
%
% traj_temp = reshape(traj,[128 4795 3]);
% traj_temp = traj_temp(:,1:first_frames,:);
% traj = reshape(traj_temp,[128*first_frames 3]);
%
% data_temp = reshape(data,[128 4795 1]);
% data_temp = data_temp(:,1:first_frames);
% data = reshape(data_temp,[128*first_frames 1]);
%
% weights_temp = reshape(weights,[128 4795 1]);
% weights_temp = weights_temp(:,1:first_frames);
% weights = reshape(weights_temp,[128*first_frames 1]);


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
figure();
imslice(phase_vol,'Phase');
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


base = 'tr6000';



% % Save volume
nii = make_nii(abs(recon_vol));
save_nii(nii, [base '_mag.nii'], 16);
nii = make_nii(abs(phase_vol));
save_nii(nii, [base '_phase.nii'], 16);
% nii = make_nii(fft_vol);
% save_nii(nii, [base '_fft.nii'], 16);
