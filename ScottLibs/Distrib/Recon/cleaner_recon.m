% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% Start with a clean slate
clc; clear all; close all;

% Define reconstruction options
headerfilename = filepath('C:\Users\ScottHaileRobertson\Desktop\ergys\Scan3\P14848.7');
% datafilename = filepath();
datafilename = '';
overgridfactor = 2;
nNeighbors = 3;
scale = 0.5;
dcf_iter = 25;
exact = 0; % CAUTION - this will make recon EXTREMELY slow!
exact_dct_iter = 0;
useAllPts = 1;

% Read in the file and prepare for generic reconstruction
[revision, logo] = ge_read_rdb_rev_and_logo(headerfilename);
[data, traj, weights, header] = GE_Recon_Prep(headerfilename, ...
    floor(revision), datafilename);

%% Calculate Sample Density Corrections
inv_scale = 1/scale;
N = floor(scale*header.MatrixSize);
if(useAllPts)
    traj = 0.5*traj;
    N = 2*N;
end
J = [nNeighbors nNeighbors nNeighbors];
K = ceil(N*overgridfactor);

%% Throw away data outside the BW
throw_away = find((traj(:,1)>0.5) + (traj(:,2)>0.5) + (traj(:,3)>0.5) + ...
    (traj(:,1)<-0.5) + (traj(:,2)<-0.5) + (traj(:,3)<-0.5));
traj(throw_away(:),:)=[];
data(throw_away(:))=[];

% optimize min-max error accross volume
A = Gmri(inv_scale*traj, true(N), 'fov', N, 'nufft_args', {N,J,K,N/2,'minmax:kb'});
clear N K J traj nuft_a;

disp('Itteratively calculating density compensation coefficients...');
wi = 1./abs(A.arg.Gnufft.arg.st.p * ones(A.arg.Gnufft.arg.st.Kd)); % Reasonable first guess

% Calculate density compensation using Pipe method
for iter = 1:dcf_iter
    disp(['   Iteration:' num2str(iter)]);
    wi = abs(wi ./ ((A.arg.Gnufft.arg.st.p * (A.arg.Gnufft.arg.st.p'*wi))));
end

%% Reconstruct image
disp('Reconstructing data...');
% Uses exp_xform_mex.c if exact recon
recon_vol = A' * (wi .* data(:));
recon_vol = reshape(recon_vol,A.idim);

% Filter
% recon_vol = FermiFilter(recon_vol,0.1/scale, 0.85/scale);

%Show output
figure();
imslice(abs(recon_vol),'Reconstruction');

% Save volume
nii = make_nii(abs(recon_vol));
save_nii(nii, 'recon_vol.nii', 16);

