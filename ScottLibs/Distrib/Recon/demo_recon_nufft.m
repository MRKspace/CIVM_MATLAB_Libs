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

% Create reconstruction object
reconObj = ConjugatePhaseReconstructionObject(traj, header, ...
    overgridfactor, scale, nNeighbors, useAllPts, dcf_iter);

% Reconstruct data
recon_vol = reconObj.reconstruct(data);

% Filter
% recon_vol = FermiFilter(recon_vol,0.1/scale, 0.85/scale);

%Show output
figure();
imslice(abs(recon_vol),'Reconstruction');

% % Save volume
nii = make_nii(abs(recon_vol));
save_nii(nii, 'recon_vol.nii', 16);

