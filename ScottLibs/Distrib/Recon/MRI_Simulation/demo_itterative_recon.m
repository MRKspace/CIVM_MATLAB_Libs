% Start with a clean slate
clc; clear all; close all;

%% Simulation parameters
fov = 250; %mm
Ndisp = 256; % pixels

% Make phantom
obj = mri_objects('fov', fov, 'case1');

% Get masks for all objects


% Make image
u1d = [-Ndisp/2:Ndisp/2-1] / Ndisp; %mm
[u v] = ndgrid(u1d, u1d);
cart_kspace = reshape(obj.kspace(u(:), v(:)),[Ndisp Ndisp]);
ideal_im = fftshift(ifftn(fftshift(cart_kspace)));
figure();
imslice(abs(ideal_im));
title('Ideal image');
colormap(gray);
colorbar();
axis image;

% Create trajectories
Nsz = Ndisp/4;
N = [Nsz Nsz];
nrays = 48;
npts = Nsz;
[traj omega wi] = mri_trajectory('radial', {'na', nrays, 'nr', npts-1}, N, fov, {'voronoi'});
figure()
plot(omega(:,1),omega(:,2),'-r');
axis(pi*[-1 1 -1 1]);
axis square;
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

% Calculate white gaussian noise
% pct = 0.05;
% snr = 10^(pct/20);
% noise = data - awgn(data,snr,'measured');
noise_pct = 0.03;
noise = (max(abs(data(:)))) * (noise_pct*rand(size(data))-(noise_pct/2));

% Decay signals randomly
min_val = 0.5;
flip_angle = acos(min_val^(1/(nrays-1)))
decay_weight = cos(flip_angle).^([0:(nrays-1)]);
decay_weight = repmat(decay_weight,[npts, 1]);
decay_weight = decay_weight(:);
data = data .* decay_weight;

% add noise
data = data + noise;
figure();
surf(abs(reshape(data,[npts nrays])));
colormap(jet);
shading interp;
title('Noisy fft magnitude');

% Conjugate phase reconstruction
recon_vol = Am' * (wi .* data);
recon_conj = embed(recon_vol, mask);
figure();
imslice(abs(recon_conj));
colormap(gray);
axis image;
title('Conjugate Phase Recon');
colorbar();

% Conjugate phase reconstruction with naive decay correction
recon_conj_naive = Am' * (wi .* data ./decay_weight);
recon_conj_naive = embed(recon_conj_naive, mask);
figure();
imslice(abs(recon_conj_naive));
colormap(gray);
axis image;
title('Conjugate Phase Recon with naive decay correction');
colorbar();

% Decay correct NUFFT weightings
[m n] = size(Am.arg.Gnufft.arg.st.p.arg.G);
[i j s] = find(Am.arg.Gnufft.arg.st.p.arg.G);
kw = sparse(i,j,nonzeros(Am.arg.Gnufft.arg.st.p.arg.G).*decay_weight(i),m ,n, length(i));
sum_kw = nonzeros(sum(kw(i,j)));
newGvals = nonzeros(kw')./sum_kw(j);
npt_ = length(j);
for idx = 1:npt_
    Am.arg.Gnufft.arg.st.p.arg.G(i(idx),j(idx))=newGvals(idx);
end
% Am.arg.Gnufft.arg.st.p.arg.G(i,j)=nonzeros(kw')./sum_kw(j);

% Am.arg.Gnufft.arg.st.p.arg.G
clear signal_weights sum_kw kw i j s m n;

recon_conj2 = Am' * (wi .* data ./decay_weight );
recon_conj2 = embed(recon_conj2, mask);
figure();
imslice(abs(recon_conj2));
colormap(gray);
axis image;
title('Conjugate Phase Recon - smart weighting');
colorbar();

% % Congugate Gradient with no penalty
niter = 10;
recon_pcgq = qpwls_pcg1(recon_conj_naive(:), Am, 1, data, 0, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
recon_pcgq  = reshape(recon_pcgq, [N niter]);
figure();
imslice(abs(recon_pcgq));
colormap(gray);
axis image;
title('Itterative reconstruction - no weighting');
colorbar();

% Congugate Gradient with naive weighting
recon_pcgq_naive = qpwls_pcg1(recon_conj_naive(:), Am, 1, data./decay_weight, 0, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
recon_pcgq_naive  = reshape(recon_pcgq_naive, [N niter]);
figure();
imslice(abs(recon_pcgq_naive));
colormap(gray);
axis image;
title('Itterative reconstruction - naive weighting');
colorbar();

% Congugate Gradient with smart weighting
snr_est = decay_weight;
weighting = Gdiag(snr_est);
recon_pcgq_smart = qpwls_pcg1(recon_conj_naive(:), Am, weighting, data./decay_weight, 0, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
recon_pcgq_smart  = reshape(recon_pcgq_smart, [N niter]);
figure();
imslice(abs(recon_pcgq_smart));
colormap(gray);
axis image;
title('Itterative reconstruction - smart weighting');
colorbar()

% Congugate Gradient with smart weighting

recon_pcgq_smart2 = qpwls_pcg1(0*recon_conj_naive(:), Am, weighting, data./decay_weight, 0, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
recon_pcgq_smart2  = reshape(recon_pcgq_smart2, [N niter]);
figure();
imslice(abs(recon_pcgq_smart2));
colormap(gray);
axis image;
title('Itterative reconstruction - smart weighting2');
colorbar()

% % Penalized Congugate Gradient with quadratic penalty
% niter = 20;
% weighting = Gdiag(decay_weight);
% beta = 2000 % good for quadratic
% C = Cdiff(sqrt(beta) * mask, 'edge_type', 'tight');
% recon_pcgq = qpwls_pcg1(0*recon_vol(:), Am, weighting, data./decay_weight, ...
%     C, 'niter', niter, 'isave',1:niter)*prod(N/Ndisp);
% recon_pcgq  = reshape(recon_pcgq, [N niter]);
% figure();
% imslice(abs(recon_pcgq));
% colormap(gray);
% axis image;
% title(['Beta = ' num2str(beta)]);
% colorbar();

% Penalized Congugate Gradient with edge-preserving penalty
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

% % Penalized Congugate Gradient with edge-preserving penalty
% recon_pcg_edge = pwls_pcg1(0*recon_vol(:), Am, weighting, data, R, 'niter', niter,'isave',1:niter)/(4^2);
% recon_pcg_edge = embed(recon_pcg_edge, mask);
% figure();
% imagesc(abs(recon_pcgq));
% colormap(gray);
% axis image;
% title('Edge-preserving penalty with decay weights');
% colorbar();

% Show roi info [topl_x, topl_y, botr_x, botr_y ideal_val name]
R1 = [16 18 23 23 2];
R2 = [40 29 51 37 2];
B1 = [37 10 56 23 1];
B2 = [37 43 56 56 1];
B3 = [11 28 28 42 1];
O1 = [2 1 62 5 0];

titles = {'Big rectangle', ...
    'Medium rectangle', ...
    'Top right Background', ...
    'Bottom right filler', ...
    'Middle left filler', ...
    'Top outer'}

rois = {R1 R2 B1 B2 B3 O1};

% titles = {'Big rectangle'}
% 
% rois = {R1};
iter_show = 3;

for i = 1:length(rois)
    exact_data = rois{i}(5);
    conj_data = abs(recon_conj(rois{i}(1):rois{i}(3),rois{i}(2):rois{i}(4)));
    conj_naive_data = abs(recon_conj_naive(rois{i}(1):rois{i}(3),rois{i}(2):rois{i}(4)));
    
    pcgq_data = abs(recon_pcgq(rois{i}(1):rois{i}(3),rois{i}(2):rois{i}(4),iter_show));
    pcgq_naive_data = abs(recon_pcgq_naive(rois{i}(1):rois{i}(3),rois{i}(2):rois{i}(4),iter_show));
    pcgq_smart_data = abs(recon_pcgq_smart(rois{i}(1):rois{i}(3),rois{i}(2):rois{i}(4),iter_show));
    pcgq_smart_data2 = abs(recon_pcgq_smart2(rois{i}(1):rois{i}(3),rois{i}(2):rois{i}(4),iter_show));
    
    data_ = [exact_data(:); ...
        conj_data(:); ...
        conj_naive_data(:); ...
        pcgq_data(:); ...
        pcgq_naive_data(:); ...
        pcgq_smart_data(:); ...
        pcgq_smart_data2(:)];
    names =[repmat('Exact                      ',[size(exact_data(:))]); ...
            repmat('Conj. Grad. no correction  ',[size(conj_data(:))]); ...
            repmat('Conj. Grad. naive corrected',[size(conj_naive_data(:))]); ...
            repmat('Iterative no correction    ',[size(pcgq_data(:))]); ...
            repmat('Iterative naive corrected  ',[size(pcgq_naive_data(:))]); ...
            repmat('Iterative smart corrected  ',[size(pcgq_smart_data(:))]); ...
            repmat('Iterative smart corrected2 ',[size(pcgq_smart_data(:))])];
    
    figure();
    boxplot(data_, names);
    title([titles{i}])
end