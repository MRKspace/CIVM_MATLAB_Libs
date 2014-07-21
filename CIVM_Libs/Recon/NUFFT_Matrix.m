function nufft_matrix = NUFFT_Matrix(traj, N, J, K, kernel_lookup)
% Constructs a NUFFT Matrix
%
% Nomenclature:
%     M = # data samples
%     K = # image voxels (no oversampling)
%     d = # data samples
% Inputs:
%     traj -> kspace trajectories (scaled -0.5 to 0.5 for pos/neg Nyquist
%     limits)
%     N    -> 
%     J    -> # neighbors
%     K    -> # image voxels (oversampled)
%
% Assumes dimmensions:
%     traj -> [M x d]
%     N    -> [d x 1]
%     J    -> [d x 1]
%     K    -> [d x 1]

%% Calculate voxel locations of trajectories
d = length(N);
traj_vox = zeros(size(traj)); % initialize
for di=1:d
	traj_vox(:,di) = (0.5+traj(:,di))*N(di);
end

%% Calculate all offset locations (J^d of them)




