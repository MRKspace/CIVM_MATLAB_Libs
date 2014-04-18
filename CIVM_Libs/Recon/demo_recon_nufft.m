% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% Start with a clean slate
clc; clear all; close all;

% Define reconstruction options
if(exist('~/.matlab_recon_prefs.mat'))
	load('~/.matlab_recon_prefs.mat');
end

% Get pfile
if(exist('pfile_root_dir','var'))
	headerfilename = filepath(pfile_root_dir);
else
	headerfilename = filepath();
end

% datafilename = filepath();
datafilename = '';
overgridfactor = 2;
nNeighbors = 3;
scale = [1 1 1]; % Scales the matrix dimmensions
dcf_iter = 25;
useAllPts = 1;

% Read in the file and prepare for generic reconstruction
[revision, logo] = ge_read_rdb_rev_and_logo(headerfilename);
[data, traj, weights, header] = GE_Recon_Prep(headerfilename, ...
    floor(revision), datafilename);

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

%Show output
figure();
imslice(abs(recon_vol),'Reconstruction');

% % Save volume
nii = make_nii(abs(recon_vol));
save_nii(nii, 'recon_vol.nii', 16);
