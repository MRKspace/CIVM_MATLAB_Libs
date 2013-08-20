% Start with a clean slate
clc; clear all; close all;

%% Simulation parameters
fov =250; %mm
Ndisp = 128; % pixels
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
imslice(abs(ideal_im),'Ideal image');
title('Ideal image');
colormap(gray);
colorbar();
axis image;

figure();
imslice(log(abs(cart_kspace)),'Ideal FFT image');
title('Ideal FFT image');
colormap(gray);
colorbar();
axis image;

x1d = linspace(-1,1,Ndisp); %mm
[x,y]=meshgrid(x1d,x1d );
r = sqrt(x.^2+y.^2);
cropped_kspace = cart_kspace.*(r<1);
cropped_im = fftshift(fftn(fftshift(cropped_kspace)));

% figure();
% imagesc(log(abs(cropped_kspace))); colormap(gray); colorbar();axis image;title('Cropped ideal kspace');

figure();
imagesc(abs(cropped_im)); colormap(gray); colorbar();axis image; title('Cropped ideal kspace image');

% Create trajectories
Nsz = Ndisp;
N = [Nsz Nsz];
undersamp_pct = 0.3;
nrays = round(pi*Nsz*undersamp_pct)
npts = round(Nsz/2);
[traj omega wi] = mri_trajectory('radial', {'na', nrays, 'nr', npts-1}, N, fov, {'voronoi'});
% figure()
% plot(omega(:,1),omega(:,2),'.r');
% axis(pi*[-1 1 -1 1]);
% axis square;
% title('Trajectories');

% Create NUFFT Object
J = [3 3];
K = overgridfactor*N;
mask = true(N);
Am = Gmri(traj, mask, 'fov', fov, 'nufft_args', {N,J,N,N/2,'kaiser'});

% Calculate data
data = obj.kspace(traj(:,1), traj(:,2))*prod(N/fov);
% figure();
% surf(abs(reshape(data,[npts nrays])));
% colormap(jet);
% shading interp;
% title('Exact fft magnitude');

% Calculate white gaussian noise
snr = 100;
snr_db = 20*log10(snr);
noise = data - awgn(data,snr_db,'measured');

% Decay signals randomly
min_val = 0.3;
flip_angle = acos(min_val^(1/(nrays-1)))
decay_weight = cos(flip_angle).^([0:(nrays-1)]);
decay_weight = repmat(decay_weight,[npts, 1]);
decay_weight = decay_weight(:);

% % add noise
data = data .* decay_weight + noise;
figure();
surf(abs(reshape(data,[npts nrays])));
colormap(jet);
shading interp;
title('Noisy fft magnitude');

% % Overgridded fft image
% recon_vol2 = Am.arg.Gnufft.arg.st.p' * (wi .* data )
% recon_vol2 = embed(recon_vol2, mask);
% recon_vol2 = fftshift(recon_vol2);
% 
% figure();
% imslice(log(abs(recon_vol2))); title('Overgridded kspace image');

disp('Itteratively calculating density compensation coefficients...');
dcf_iter = 20;
wi = 1./abs(Am.arg.Gnufft.arg.st.p * ones(Am.arg.Gnufft.arg.st.Kd)); % Reasonable first guess

% Calculate density compensation using Pipe method
for iter = 1:dcf_iter
    disp(['   Iteration:' num2str(iter)]);
    wi = abs(wi ./ (Am.arg.Gnufft.arg.st.p * Am.arg.Gnufft.arg.st.p'*wi));
end

%% Conjugate phase reconstruction
% Raw data - no weighting
recon_conj_raw = Am' * (wi .* data );
recon_conj_raw = embed(recon_conj_raw, mask);
figure();
imslice(abs(recon_conj_raw),'Conjugate Phase Recon - pipe weights');
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
axis image;
title('Conjugate Phase Recon - naive weighting');
colorbar();

%% Conjugate Gradient reconstruction
% Raw data - no weighting
niter = 200;
recon_pcgq_raw = qpwls_pcg1(0*mask(:), Am, 1, data, 0, ...
    'niter', niter, 'isave',1:niter);
recon_pcgq_raw  = reshape(recon_pcgq_raw, [size(mask) niter]);
figure();
imslice(abs(recon_pcgq_raw));
colormap(gray);
axis image;
title('Itterative reconstruction - raw data');
colorbar()

% Naive weighting
recon_pcgq_naive = qpwls_pcg1(0*mask(:), Am, 1, data./decay_weight, 0, ...
    'niter', niter, 'isave',1:niter);
recon_pcgq_naive  = reshape(recon_pcgq_naive, [size(mask) niter]);
figure();
imslice(abs(recon_pcgq_naive));
colormap(gray);
axis image;
title('Itterative reconstruction - naive weighting');
colorbar()

% Test 1 of SNR weighting
[row, col, proximity_vals] = find(Am.arg.Gnufft.arg.st.p.arg.G);
[m,n]=size(Am.arg.Gnufft.arg.st.p.arg.G);
snr_vals = decay_weight(row);

% Test fix?
Am.arg.Gnufft.arg.st.p = sparse(row,col,snr_vals.*proximity_vals,m,n,length(proximity_vals));
Am.arg.Gnufft.arg.st.p = Gsparse(Am.arg.Gnufft.arg.st.p,'odim', [length(data(:)) 1], 'idim', [prod(Am.arg.Gnufft.arg.st.Kd) 1]);

% Calculate density compensation using Pipe method
for iter = 1:dcf_iter
    disp(['   Iteration:' num2str(iter)]);
    wi = abs(wi ./ (Am.arg.Gnufft.arg.st.p * Am.arg.Gnufft.arg.st.p'*wi));
end

%% Conjugate phase reconstruction
% Raw data - no weighting
recon_conj_raw = Am' * (wi .* data );
recon_conj_raw = embed(recon_conj_raw, mask);
figure();
imslice(abs(recon_conj_raw),'Conjugate Phase Recon - pipe weights');
colormap(gray);
axis image;
title('Conjugate Phase Recon - raw data');
colorbar();

%% Conjugate gradient weighting
recon_pcgq_naive = qpwls_pcg1(0*mask(:), Am, 1, data, 0, ...
    'niter', niter, 'isave',1:niter);
recon_pcgq_naive  = reshape(recon_pcgq_naive, [size(mask) niter]);
figure();
imslice(abs(recon_pcgq_naive));
colormap(gray);
axis image;
title('Itterative reconstruction - naive weighting');
colorbar()

