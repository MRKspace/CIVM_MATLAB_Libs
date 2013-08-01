% Start with a clean slate
clc; clear all; close all;

%% Simulation parameters
fov = 250; %mm
Ndisp = 256; % pixels

% Make phantom
obj = mri_objects('fov', fov, 'case1');

% Make image
u1d = [-Ndisp/2:Ndisp/2-1] / Ndisp; %mm
[u v] = ndgrid(u1d, u1d);
cart_kspace = reshape(obj.kspace(u(:), v(:)),[Ndisp Ndisp]);
ideal_im = fftshift(ifftn(fftshift(cart_kspace)));
figure();
imagesc(abs(ideal_im));
colormap(gray);
title('Ideal image');
colorbar();
axis image;

% Create trajectories
N = [Ndisp Ndisp]/4;
[traj omega wi] = mri_trajectory('radial', {'na', 12}, N, fov, {'voronoi'});
figure()
plot(omega(:,1),omega(:,2),'.r');
axis(pi*[-1 1 -1 1]);
title('Trajectories');

% Create NUFFT Object
J = [3 3];
K = 2*N;
mask = true(N);
Am = Gmri(traj, mask, 'fov', fov, 'nufft_args', {N,J,K,N/2,'minmax:kb'});

% Calculate data
data = obj.kspace(traj(:,1), traj(:,2));

% Add noise
data = data + 0.5 * randn(size(data));

% Conjugate phase reconstruction
recon_vol = Am' * (wi .* data) * prod(N/Ndisp);
recon_vol = embed(recon_vol, mask);
figure();
imagesc(abs(recon_vol));
colormap(gray);
axis image;
title('Conjugate Phase Recon');
colorbar();

% Penalized Congugate Gradient with quadratic penalty
niter = 100;
beta = 100 % good for quadratic
C = Cdiff(sqrt(beta) * mask, 'edge_type', 'tight');
recon_pcgq = qpwls_pcg1(0*recon_vol(:), Am, 1, data, C, 'niter', niter)*prod(N/Ndisp);
recon_pcgq  = embed(recon_pcgq (:,end), mask);
figure();
imagesc(abs(recon_pcgq));
colormap(gray);
axis image;
title('Penalized Conjugate gradient with quadratic penalty');
colorbar();

% Penalized Congugate Gradient with edge-preserving penalty
delta = 0.3;
R = Robject(mask, 'edge_type', 'tight', 'type_denom', 'matlab', ...
		'potential', 'hyper3', 'beta', beta, 'delta', delta);
recon_pcg_edge = pwls_pcg1(0*recon_vol(:), Am, 1, data, R, 'niter', niter)/(4^2);
recon_pcg_edge = embed(recon_pcg_edge, mask);
figure();
imagesc(abs(recon_pcgq));
colormap(gray);
axis image;
title('Penalized Conjugate gradient with edge-preserving penalty');
colorbar();
