%Do all prep work on first file
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
undo_loopfactor = 0;    % No need to undo loopfactor, they are in order the same way the trajectories are
precision = 'int16';      % Can we read this from header? CSI extended mode uses int32

% Typical Recon Params
kernel_width   = 1;
overgridfactor = 2;
scale = 1.6;
itter = 30;

% Read header
pfile_name = filepath()
header = ge_read_header(pfile_name, hdr_off, byte_order);

% Read pfile data
recon_data = Recon_Data();
recon_data = recon_data.readPfileData(pfile_name,byte_order, precision,header);
recon_data = recon_data.removeBaselines(header);
recon_data.Data = recon_data.Data(:);

% Get prep data
lookup_name = [num2str(recon_data.Nframes) '_' ...
    num2str(header.rdb.rdb_hdr_user23) '_' ...
    num2str(header.rdb.rdb_hdr_user12) '_' ...
    num2str(header.rdb.rdb_hdr_user1)  '_' ...
    num2str(header.rdb.rdb_hdr_frame_size) '_' ...
    num2str(header.rdb.rdb_hdr_user22) '_' ...
    num2str(overgridfactor)  '_' ...
    num2str(scale)  '_' ...
    num2str(kernel_width)  '_' ...
    num2str(itter) ...
    '.mat'];

nufftObj = {};

disp(['Creating NUFFT Object for ' lookup_name]);
rad_traj  = calc_radial_traj_distance(header);
traj = 2*pi*calc_archimedian_spiral_trajectories(...
    recon_data.Nframes, header.rdb.rdb_hdr_user23, ...
    rad_traj)';
num_points   = header.rdb.rdb_hdr_frame_size;
output_dims  = uint32(round(scale*[num_points num_points num_points]));

%Prepare NUFFT object
N = round(scale*[num_points num_points num_points]);
J = ceil(overgridfactor*[kernel_width kernel_width kernel_width]);
K = N*overgridfactor;
nufft_st = nufft_init(traj,N,J,K,N/2,'minmax:kb');

%Prepare GNUFFT object
nufftObj.G = Gnufft(nufft_st);
clear nufft_st;

% Calculate DCF
w = ones(size(recon_data.Data));
P = nufftObj.G.arg.st.p;

for ii=1:itter
    itteration = ii
    tmp = P * (P' * w);
    w = w ./ real(tmp);
end

% Reconstruct
clear J K N P byte_order hdr_off header ii itter itteration kernel_width;
clear lookup_name num_points output_dims overgridfactor pfile_name;
clear precision rad_traj scale tmp traj undo_loopfactor;
data = recon_data.Data;
G = nufftObj.G;
mask =  true(nufftObj.G.st.Nd);
clear nufftObj recon_data
recon_vol = embed(G' * (w .* data), mask);

% Save images
%     saveVolumeAsImageStack(abs(recon_vol), 'test', 'tiff');
% recon_vol = abs(recon_vol);
% recon_vol = recon_vol-min(recon_vol(:));
% recon_vol = recon_vol/max(recon_vol(:));
% imslice(abs(recon_vol));
