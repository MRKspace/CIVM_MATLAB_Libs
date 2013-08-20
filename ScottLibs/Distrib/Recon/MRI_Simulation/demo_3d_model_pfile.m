% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm and RF weightings. Kaiser bessel kernel is used.

% Start with a clean slate
clc; clear all; close all;

% Define reconstruction options
options.headerfilename = filepath();
% options.datafilename = filepath();
options.datafilename = '';
options.overgridfactor = 3;
options.nNeighbors = 3;
options.scale = 2;
options.dcf_iter = 25;

[revision, logo] = ge_read_rdb_rev_and_logo(options.headerfilename);
[data, traj, decay_weight, header] = GE_Recon_Prep(options.headerfilename, ...
    floor(revision), options.datafilename);

N = floor(options.scale*header.MatrixSize);
N = 2*round((N-1)/2)+1; % Make sure N is even
J = [options.nNeighbors options.nNeighbors options.nNeighbors];
K = ceil(N*options.overgridfactor);

%% Calculate Sample Density Corrections
inv_scale = 1/options.scale;
N = floor(options.scale*header.MatrixSize);
2*round((N-1)/2)+1; % Make sure N is even
J = [options.nNeighbors options.nNeighbors options.nNeighbors];
K = ceil(N*options.overgridfactor);
mask = zeros(N);

% optimize min-max error accross volume
reconObj.G = Gmri(inv_scale*traj, true(N), 'fov', N, 'nufft_args', {N,J,K,N/2,'kaiser'});
clear N K J traj nuft_a;

disp('Itteratively calculating density compensation coefficients...');
reconObj.wt.pipe = 1./abs(reconObj.G.arg.Gnufft.arg.st.p * ...
    ones(reconObj.G.arg.Gnufft.arg.st.Kd)); % Reasonable first guess
reconObj.wt.max_itter = options.dcf_iter;

% Calculate density compensation using Pipe method
for iter = 1:options.dcf_iter
    disp(['   Iteration:' num2str(iter)]);
    reconObj.wt.pipe = abs(reconObj.wt.pipe ./ ...
        ((reconObj.G.arg.Gnufft.arg.st.p * ...
        (reconObj.G.arg.Gnufft.arg.st.p'*(reconObj.wt.pipe)))));
end

%% Conjugate phase
% disp('Reconstructing data...');
% % Uses exp_xform_mex.c if exact recon
% recon_conj_raw = reconObj.G' * (reconObj.wt.pipe .* data(:));
% recon_conj_raw = reshape(recon_conj_raw, reconObj.G.idim);
% figure();
% imslice(abs(recon_conj_raw),'Conj Phase - raw');
% colormap(gray);
% axis image;
% title('Conj Phase - raw');
% colorbar();


%% Naive Conjugate Gradient
niter = 40;
startIter = 1;
recon_pcgq_naive = qpwls_pcg1(0*mask(:), reconObj.G, ...
    1, data./decay_weight, 0, 'niter', niter, 'isave',startIter:niter);
recon_pcgq_naive  = reshape(recon_pcgq_naive, [size(mask) niter-startIter+1]);
figure();
imslice(abs(recon_pcgq_naive),'Iterative - naive weighted');
colormap(gray);
axis image;
title('Model based Itterative reconstruction - naive weighting');
colorbar();

%% RF weighted Conjugate Gradient
% guess_iter = 26;
% start_guess = recon_pcgq_naive(:,:,:,guess_iter);
% clear recon_pcgq_naive;
% close all;
% niter = 500;
% startIter = 300;
% data_ideal = 1;
% recon_pcgq_smart = qpwls_pcg1_snrweighted(mask, reconObj.G, ...
%     1, data, 0, decay_weight, data_ideal, 'niter', niter, 'isave',startIter:niter);
% recon_pcgq_smart  = reshape(recon_pcgq_smart, [size(mask) niter-startIter+1]);
% figure();
% imslice(abs(recon_pcgq_smart),'Iterative - RF weighted');
% colormap(gray);
% axis image;
% title('Model based Itterative reconstruction - RF weighting');
% colorbar();


% % mask = ones(size(recon_vol));
% % beta = 2^-7 * length(data);	% good for quadratic
% % Rq = Reg1(mask, 'beta', beta,'type_penal', 'mat');
% % % Rq = Robject(mask, 'beta', beta);
% recon_vol2 = qpwls_pcg1(0*recon_vol(:), options.reconObj.G, ...
%     Gdiag(weights), data(:)./weights, Rq.C, ... 
% 		'niter', niter,'chat',1,'isave',startSave:niter);
% 
% 
% 
% nii = make_nii(abs(recon_vol2));
% save_nii(nii, 'recon_15_iter.nii', 16);
