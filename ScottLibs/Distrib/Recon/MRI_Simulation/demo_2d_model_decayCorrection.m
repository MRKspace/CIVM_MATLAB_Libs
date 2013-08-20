% Start with a clean slate
clc; clear all; close all;

%% Simulation parameters
fov =250; %mm
Ndisp = 256; % pixels
overgridfactor = 3;

% Make phantom
obj = mri_objects('fov', fov, 'case1');

% Make image
u1d = [-Ndisp/2:Ndisp/2-1] / fov; %mm
[u v] = ndgrid(u1d, u1d);
cart_kspace = obj.kspace(u(:), v(:))*prod([Ndisp Ndisp]/fov);
cart_kspace = reshape(cart_kspace,[Ndisp Ndisp]);
ideal_im = fftshift(ifftn(fftshift(cart_kspace)));

figure();
imslice(abs(ideal_im));
caxis([0 3]);
title('Ideal image');
colormap(gray);
colorbar();
axis image;

figure();
imslice(log(abs(cart_kspace)));
title('Ideal FFT image');
colormap(gray);
colorbar();
axis image;

x1d = linspace(-1,1,Ndisp); %mm
[x,y]=meshgrid(x1d,x1d );
r = sqrt(x.^2+y.^2);
cropped_kspace = cart_kspace.*(r<1);
cropped_im = fftshift(fftn(fftshift(cropped_kspace)));

figure();
imagesc(log(abs(cropped_kspace))); colormap(gray); colorbar();axis image;

figure();
imagesc(abs(cropped_im)); colormap(gray); colorbar();axis image;

% Create trajectories
Nsz = Ndisp;
N = [Nsz Nsz];
undersamp_pct = 4*pi*32^2/4601; % same as ventilation
nrays = round(pi*Nsz*undersamp_pct)
npts = round(Nsz/2);
[traj omega wi] = mri_trajectory('radial', {'na', nrays, 'nr', npts-1}, N, fov, {'voronoi'});
figure()
plot(traj(:,1),traj(:,2),'.r');
axis(pi*[-1 1 -1 1]);
axis square;
title('Trajectories');

% Create NUFFT Object
J = [3 3];
K = overgridfactor*N;
mask = true(N);
Am = Gmri(traj, mask, 'fov', fov, 'nufft_args', {N,J,N,N/2,'kaiser'});

% Calculate data
data = obj.kspace(traj(:,1), traj(:,2))*prod(N/fov);
figure();
surf(abs(reshape(data,[npts nrays])));
colormap(jet);
shading interp;
title('Exact fft magnitude');

% Calculate white gaussian noise
snr = 100;
snr_db = 20*log10(snr);
noise = data - awgn(data,snr_db,'measured');
% noise = zeros(size(data));

% Decay signals randomly
min_val = 0.3;
flip_angle = acos(min_val^(1/(nrays-1)))
decay_weight = cos(flip_angle).^([0:(nrays-1)]);
decay_weight = repmat(decay_weight,[npts, 1]);
decay_weight = decay_weight(:);
data = data .* decay_weight + noise;

% Add noise
figure();
surf(abs(reshape(data,[npts nrays])));
colormap(jet);
shading interp;
title('Noisy fft magnitude');

%% Calculate DCF
dcf_iter = 20;
wi = 1./abs(Am.arg.Gnufft.arg.st.p * ones(Am.arg.Gnufft.arg.st.Kd)); % Reasonable first guess
for iter = 1:dcf_iter
    disp(['   Iteration:' num2str(iter)]);
    wi = abs(wi ./ ((Am.arg.Gnufft.arg.st.p * (Am.arg.Gnufft.arg.st.p'*(wi)))));
end

%% Conjugate phase reconstruction
% Raw data - no weighting
recon_conj_raw = Am' * (wi .* data );
recon_conj_raw = embed(recon_conj_raw, mask);
figure();
imslice(abs(recon_conj_raw),'Conjugate Phase Recon - raw data');
% caxis([0 3]); % Why are these scaled wrong?
colormap(gray);
axis image;
title('Conjugate Phase Recon - raw data');
colorbar();

% Naive weighting
recon_conj_naive = Am' * (wi .* data ./decay_weight );
recon_conj_naive = embed(recon_conj_naive, mask);
figure();
imslice(abs(recon_conj_naive),'Conjugate Phase Recon - naive weighting');
colormap(gray);
% caxis([0 3]);
axis image;
title('Conjugate Phase Recon - naive weighting');
colorbar();

%% Conjugate Gradient reconstruction
% Raw data - no weighting
niter = 150;
recon_pcgq_raw = qpwls_pcg1(0*recon_conj_raw(:), Am, 1, data, 0, ...
    'niter', niter, 'isave',1:niter);
recon_pcgq_raw  = reshape(recon_pcgq_raw, [size(mask) niter]);
figure();
imslice(abs(recon_pcgq_raw),'Itterative reconstruction - raw data');
colormap(gray);
caxis([0 3]);
axis image;
title('Itterative reconstruction - raw data');
colorbar()

% Naive weighting
recon_pcgq_naive = qpwls_pcg1(0*recon_conj_raw(:), Am, 1, data./decay_weight, 0, ...
    'niter', niter, 'isave',1:niter);
recon_pcgq_naive  = reshape(recon_pcgq_naive, [size(mask) niter]);
figure();
imslice(abs(recon_pcgq_naive),'Itterative reconstruction - naive weighting');
colormap(gray);
caxis([0 3]);
axis image;
title('Itterative reconstruction - naive weighting');
colorbar()

% Model based reconstruction with RF weighting
snr_est = decay_weight;
weighting = Gdiag(snr_est);

recon_pcgq_smart = qpwls_pcg1_snrweighted(0*recon_conj_raw(:), Am, weighting, data, 0, ...
    decay_weight, cropped_im, 'niter', niter, 'isave',1:niter);
recon_pcgq_smart  = reshape(recon_pcgq_smart, [size(mask) niter]);
figure();
imslice(abs(recon_pcgq_smart),'Model based Itterative reconstruction - RF weighting');
colormap(gray);
caxis([0 3]);
axis image;
title('Model based Itterative reconstruction - RF weighting');
colorbar()
