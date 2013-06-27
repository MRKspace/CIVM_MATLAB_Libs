% Get file to reconstruct
% recon_rawFile = filepath()

% Reconstruct image
% [recon_vol, header] = Recon_Noncartesian(recon_rawFile);

% Load nifti volumes
ventilation_file = filepath()
mask_file = filepath()

load(ventilation_file);
load(mask_file);
% s_size = 2;
% [x,y,z] = ndgrid(-s_size:s_size);
% se = strel(sqrt(x.^2 + y.^2 + z.^2) <= s_size);
% mask = imdilate(mask,se);

figure();imslice(abs(recon_vol),'Magnitude Image'); colorbar();

% Scan parameters
parameter.TE = 4; %ms
parameter.B0 = 2; %; % T 
parameter.FOV = [30, 30, 30]; % mm
% parameter.TE = header.ge_header.image.te/1000; %4; %ms
% parameter.B0 = header.ge_header.exam.magstrength/1000; %2; %; % T 
% parameter.FOV = [header.ge_header.rdb.rdb_hdr_user16, ...
%                  header.ge_header.rdb.rdb_hdr_user17, ...
%                  header.ge_header.rdb.rdb_hdr_user18]; % mm
gamma_bar = 638662330;% %MHz/T
parameter.gamma = gamma_bar*2*pi; %rad/(sec*T)
parameter.H = [0 0 1]; % e.g. [0 0 1] - Tells which dimmension is b0
parameter.niter = 500;

% Calculate Phase
phase = angle(recon_vol);
figure();imslice(phase,'Raw Phase'); colorbar();

% Unwrap phase
phase_unwrapped = unwrap_phase_laplacian(phase);
figure();imslice(phase_unwrapped, 'Unwrapped Phase'); colorbar();

% Remove background phase
% mask = ones(size(phase_unwrapped));
phase_unwrapped_nobackground = SphericalMeanValueFilter(phase_unwrapped,mask,4);
figure();imslice(phase_unwrapped_nobackground, 'Unwrapped Interior Phase'); colorbar();

% Calculate Susceptibility Image
[X,coeff] = calcSusceptibility_LSQR(phase_unwrapped,mask,parameter);
figure(); imslice(X, 'Susceptibility'); colorbar();
