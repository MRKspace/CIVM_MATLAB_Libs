% Start with a clean slate
clc; clear all; close all;

% Define reconstruction options
headerfilename = filepath('C:\Users\ScottHaileRobertson\Desktop\demo_organizer\organized\SUBJECT_002-043_6982_201307161332\5_DUAL\P08192.7');
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
    = GE_Recon_Prep_Dual(headerfilename, revision, datafilename);

% Create reconstruction object
reconObj = ConjugatePhaseReconstructionObject(traj, header, ...
    overgridfactor, scale, nNeighbors, useAllPts, dcf_iter);

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