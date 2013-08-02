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
Nsz = Ndisp/4;
N = [Nsz Nsz];
nrays = 50;
npts = Nsz;
[traj omega wi] = mri_trajectory('radial', {'na', nrays, 'nr', npts-1}, N, fov, {'voronoi'});
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
figure();
surf(abs(reshape(data,[npts nrays])));
colormap(jet);
shading interp;
title('Exact fft magnitude');

% Decay signals randomly
min_val = 0.3;
flip_angle = acos(min_val^(1/(nrays-1)))
decay_weight = cos(flip_angle).^([0:(nrays-1)]);
decay_weight = repmat(decay_weight,[npts, 1]);
decay_weight = decay_weight(:);
data = data .* decay_weight;
figure();
surf(abs(reshape(data,[npts nrays])));
colormap(jet);
shading interp;
title('Decayed fft magnitude');

% Add noise
data = data + 0.05 * (max(abs(data(:)))) * (rand(size(data))-0.5);
figure();
surf(abs(reshape(data,[npts nrays])));
colormap(jet);
shading interp;
title('Noisy fft magnitude');


% Conjugate phase reconstruction
recon_vol = Am' * (wi .* data) * prod(N/Ndisp);
recon_vol = embed(recon_vol, mask);
figure();
imagesc(abs(recon_vol));
colormap(gray);
axis image;
title('Conjugate Phase Recon');
colorbar();

% Congugate Gradient with no penalty
niter = 20;
weighting = Gdiag(decay_weight);
recon_pcgq = qpwls_pcg1(0*recon_vol(:), Am, 1, data, 0, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
recon_pcgq  = reshape(recon_pcgq, [N niter]);
figure();
imslice(abs(recon_pcgq));
colormap(gray);
axis image;
title('Itterative reconstruction - no weighting');
colorbar();

% Congugate Gradient with no penalty
niter = 20;
weighting = Gdiag(decay_weight);
recon_pcgq = qpwls_pcg1(0*recon_vol(:), Am, 1, data./decay_weight, 0, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
recon_pcgq  = reshape(recon_pcgq, [N niter]);
figure();
imslice(abs(recon_pcgq));
colormap(gray);
axis image;
title('Itterative reconstruction - naive weighting');
colorbar();

% Congugate Gradient with no penalty
niter = 20;
weighting = Gdiag(decay_weight);
recon_pcgq = qpwls_pcg1(0*recon_vol(:), Am, weighting, data./decay_weight, 0, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
recon_pcgq  = reshape(recon_pcgq, [N niter]);
figure();
imslice(abs(recon_pcgq));
colormap(gray);
axis image;
title('Itterative reconstruction - smart weighting');
colorbar();

% % Penalized Congugate Gradient with quadratic penalty
% beta = 100 % good for quadratic
% C = Cdiff(sqrt(beta) * mask, 'edge_type', 'tight');
% recon_pcgq = qpwls_pcg1(0*recon_vol(:), Am, weighting, data, C, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
% recon_pcgq  = embed(recon_pcgq (:,end), mask);
% figure();
% imagesc(abs(recon_pcgq),[0 2]);
% colormap(gray);
% axis image;
% title('Unweighted quadratic penalty');
% colorbar();

% % Penalized Congugate Gradient with edge-preserving penalty
% delta = 0.3;
% R = Robject(mask, 'edge_type', 'tight', 'type_denom', 'matlab', ...
% 		'potential', 'hyper3', 'beta', beta, 'delta', delta);
% recon_pcg_edge = pwls_pcg1(0*recon_vol(:), Am, weighting, data, R, 'niter', niter,'isave',1:niter)/(4^2);
% recon_pcg_edge = embed(recon_pcg_edge, mask);
% figure();
% imagesc(abs(recon_pcgq));
% colormap(gray);
% axis image;
% title('Unweighted edge-preserving penalty');
% colorbar();
% 
% % Penalized Congugate Gradient with edge-preserving penalty
% recon_pcg_edge = pwls_pcg1(0*recon_vol(:), Am, weighting, data, R, 'niter', niter,'isave',1:niter)/(4^2);
% recon_pcg_edge = embed(recon_pcg_edge, mask);
% figure();
% imagesc(abs(recon_pcgq));
% colormap(gray);
% axis image;
% title('Edge-preserving penalty with decay weights');
% colorbar();
