% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% Start with a clean slate
clc; clear all; close all;

% Define reconstruction options
headerfilename = filepath();
% datafilename = filepath();
datafilename = '';
overgridfactor = 2;
nNeighbors = 3;
scale = 1;
dcf_iter = 25;
useAllPts = 1;

% Read in the file and prepare for generic reconstruction
[revision, logo] = ge_read_rdb_rev_and_logo(headerfilename);
[data, traj, weights, header] = GE_Recon_Prep(headerfilename, ...
    floor(revision), datafilename);

inv_scale = 1/scale;
N = floor(scale*header.MatrixSize);
if(useAllPts)
    traj = 0.5*traj;
    N = 2*N;
end
traj = traj*inv_scale;
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
