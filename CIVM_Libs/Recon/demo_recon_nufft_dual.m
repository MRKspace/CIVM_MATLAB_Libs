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


% Define reconstruction options
% datafilename = filepath();
datafilename = '';
overgridfactor = 2;
nNeighbors = 3;
scale = 1;
dcf_iter = 25;
useAllPts = 1;

% Read Dual Pfile
[revision, logo] = ge_read_rdb_rev_and_logo(headerfilename);
[gas_data, dissolved_data, traj, gas_weights, dissolved_weights, header] ...
    = GE_Recon_Prep_Dual(headerfilename, floor(revision), datafilename);

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

% Reconstruct gas data
recon_vol_gas = reconObj.reconstruct(gas_data);

% Filter
% recon_vol_gas = FermiFilter(recon_vol_gas,0.1/scale, 0.85/scale);

%Show output
figure();
imslice(abs(recon_vol_gas),'Reconstruction - Ventilation');

% Save volume
nii = make_nii(abs(recon_vol_gas));
save_nii(nii, 'recon_vol_gas.nii', 16);

% Reconstruct dissolved data
recon_vol_dissolved = reconObj.reconstruct(dissolved_data);

% Filter
% recon_vol_dissolved = FermiFilter(recon_vol_dissolved,0.1/scale, 0.85/scale);

%Show output
figure();
imslice(abs(recon_vol_dissolved),'Reconstruction - Dissolved');

% Save volume
nii = make_nii(abs(recon_vol_dissolved));
save_nii(nii, 'recon_vol_dissolved.nii', 16);