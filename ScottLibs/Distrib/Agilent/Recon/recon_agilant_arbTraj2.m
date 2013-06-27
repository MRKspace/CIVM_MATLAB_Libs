clc; clear all; close all;

% load data
filename = ...
    'C:\Users\ScottHaileRobertson\Desktop\Sasha\NS1_AK1_G_1466_70_bp3dnew_v2_13.fid\';
fidfile = [filename 'fid'];
procparfile = [filename 'procpar'];

procpar = readprocpar(procparfile);
[npoints,nblocks,ntraces,bitdepth] = load_fid_hdr(fidfile);
npoints = npoints/2; % Due to complex data
pan_ang = 128;
pan_rot = 64;
data_buffer = load_fid(fidfile,nblocks,ntraces,2*npoints,bitdepth,1,[npoints pan_ang pan_rot procpar.nblocks]);
nblocks = procpar.nblocks;

% %Plot FIDS
% figure();
% plot(abs(data_buffer(1:128,:,1)));

%% Guess at trajectories to find t_off
samp_time = 1/(2*procpar.sw); % Takes twice as long since we need real, imaginary
t = 0:samp_time:samp_time*((npoints)-1);
dc_time = 3.75*samp_time
plateau_time = 128*samp_time;
ramp_time = procpar.at;

% Create Gradients
grad = (t-dc_time).*(t>dc_time).*(t<(dc_time+ramp_time)) + ... 
    (ramp_time).*(t>=(dc_time+ramp_time));
r = 0.5*(t-dc_time).^2.*(t>dc_time).*(t<(dc_time+ramp_time)) + ...
    (ramp_time).*(0.5*(ramp_time)+(t-(dc_time+ramp_time))).*(t>=(dc_time+ramp_time)); 
r = 0.5*r/max(abs(r(:)));

% %Plot gradients
% figure();
% subplot(1,3,1);plot(t,grad,'r');xlabel('time');ylabel('Gradient');
% subplot(1,3,2);plot(t,r,'-b');xlabel('time');ylabel('kspace location');

% Create radial sampling
%npoints pan_ang pan_rot
r = repmat(r',[1 pan_ang pan_rot]);
phi = linspace(0, 2*pi, pan_ang+1);
phi = phi(1:(end-1));
phi = repmat(phi,[npoints 1 pan_rot]);

theta = linspace(0, pi, pan_rot+1);
theta = theta(1:(end-1));
theta = repmat(permute(theta,[1 3 2]),[npoints pan_ang 1]);
% theta = 
kx = r.*sin(phi).*cos(theta);
ky = r.*sin(phi).*sin(theta);
kz = r.*cos(phi);
% %Plot kspace samples
% subplot(1,3,3);plot3(kx(:),ky(:),kz(:),'.b');xlabel('time');ylabel('kspace location');

%% reconstruct
% Typical Recon Params
kernel_width   = 1;
overgridfactor = 2;
itter = 3;

N = round([npoints npoints npoints]);
J = ceil(overgridfactor*[kernel_width kernel_width kernel_width]);
K = N*overgridfactor;
nufft_st = nufft_init(2*pi*[kx(:)';ky(:)';kz(:)']',N,J,K,N/2,'minmax:kb');

%Prepare GNUFFT object
nufftObj.G = Gnufft(nufft_st);

% Calculate DCF
disp('Itteratively calculating density compensation coefficients...');
w = ones([npoints pan_ang pan_rot]);
w = w(:);
P = nufftObj.G.arg.st.p;
for i=1:itter
    disp(['   Itteration ' num2str(i)]);
    tmp = P * (P' * w);
    w = w ./ real(tmp);
end
nufftObj.wt.pipe = w;

mask =  true(nufftObj.G.st.Nd);
recon_vol = zeros(size(mask));
% Sum of squares reconstruction for parallel data
disp('Reconstructing parallel data...');
% recon_vol = recon_vol + embed(nufftObj.G' * (nufftObj.wt.pipe .* data_buffer(:)), mask).^2;
for i=1:nblocks
    disp(['   coil ' num2str(i)]); 
    cur_buf = data_buffer(:,:,:,i);
    recon_vol = recon_vol + embed(nufftObj.G' * (nufftObj.wt.pipe .* cur_buf(:)), mask).^2;
end
recon_vol = sqrt(recon_vol);
clear J K N P cur_buf data_buffer kx ky kz mask nufftObj nufft_st phi procpar r theta t tmp w;