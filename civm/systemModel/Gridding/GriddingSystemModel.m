classdef GriddingSystemModel < SystemModel
	properties
		outputImageSize;
		overgridFactor;
		neighborhoodSize;
	end
	methods
		function obj = GriddingSystemModel(traj, output_image_size, ...
				overgrid_factor, neighborhood_size)
			
			% Initialize properties
			obj.outputImageSize = output_image_size;
			obj.overgridFactor = overgrid_factor;
			obj.neighborhoodSize = neighborhood_size;
			obj.reconMatrixSize = output_image_size * overgrid_factor;
			
			% Calculate gridding distances
			neigh_size = 0.5*neighborhood_size;
			neighbor_lsp = [-neigh_size:neigh_size];
			[neighbors_x neighbors_y neighbors_z] = meshgrid(neighbor_lsp, ...
				neighbor_lsp, neighbor_lsp);
			neighbors_x = neighbors_x(:);
			neighbors_y = neighbors_y(:);
			neighbors_z = neighbors_z(:);
			
			
			[sample_idx, junk] = meshgrid(1:size(traj,1),neighbors_x);
			sample_idx = sample_idx(:)';			
			
			[traj_x_mesh neigh_x_mesh] = meshgrid(obj.reconMatrixSize(1)*traj(:,1),neighbors_x);
			[traj_y_mesh neigh_y_mesh] = meshgrid(obj.reconMatrixSize(2)*traj(:,2),neighbors_y);
			[traj_z_mesh neigh_z_mesh] = meshgrid(obj.reconMatrixSize(3)*traj(:,3),neighbors_z);
			
			delta_x_mesh = mod(traj_x_mesh,1) + neigh_x_mesh;
			delta_y_mesh = mod(traj_y_mesh,1) + neigh_y_mesh;
			delta_z_mesh = mod(traj_z_mesh,1) + neigh_z_mesh;
			
			vox_x_mesh = mod(round(traj_x_mesh + neigh_x_mesh), obj.reconMatrixSize(1)) + 1;
			vox_y_mesh = mod(round(traj_y_mesh + neigh_y_mesh), obj.reconMatrixSize(2)) + 1;
			vox_z_mesh = mod(round(traj_z_mesh + neigh_z_mesh), obj.reconMatrixSize(3)) + 1;
			
			distances(1,:) = delta_x_mesh(:);
			distances(2,:) = delta_y_mesh(:);
			distances(3,:) = delta_z_mesh(:);

			
			voxel_idx = sub2ind(obj.reconMatrixSize,vox_x_mesh,vox_y_mesh,vox_z_mesh);
			voxel_idx = voxel_idx(:)';
			
% 			neighbor_mesh(:,1) = neigh_x_mesh(:);
% 			neighbor_mesh(:,2) = neigh_y_mesh(:);
% 			neighbor_mesh(:,3) = neigh_z_mesh(:);
% 			traj_mesh(:,1) = traj_x_mesh(:);
% 			traj_mesh(:,2) = traj_y_mesh(:);
% 			traj_mesh(:,3) = traj_z_mesh(:);
% 			dist_mesh = mod(traj_mesh,1) + neighbor_mesh;
% 			vox_mesh = round(traj_mesh + neighbor_mesh);
			
% 			voxel_x_mesh = round(neigh_x_mesh + traj_mesh);
% 			distances_mesh_temp = mod(neigh_x_mesh,1) + traj_mesh;
% 			distances = distances_mesh_temp(:);
% 			
% 			[traj_mesh neigh_y_mesh] = meshgrid(obj.reconMatrixSize(2)*traj(:,2),neighbors_y);
% 			voxel_y_mesh = round(neigh_y_mesh + traj_mesh);
% 			distances_mesh_temp = mod(neigh_y_mesh,1) + traj_mesh;
% 			distances(:,2) = distances_mesh_temp(:);
% 			
% 			[traj_mesh neigh_z_mesh] = meshgrid(obj.reconMatrixSize(3)*traj(:,3),neighbors_z);
% 			voxel_z_mesh = round(neigh_z_mesh + traj_mesh);
% 			distances_mesh_temp = mod(neigh_z_mesh,1) + traj_mesh;
% 			distances(:,3) = distances_mesh_temp(:);
% 			distances = distances';
			
% 			[traj_mesh neigh_x_mesh] = meshgrid(obj.reconMatrixSize(1)*traj(:,1),neighbors_x);
% 			voxel_x_mesh = round(neigh_x_mesh + traj_mesh);
% 			traj, output_image_size, overgrid_factor, neighborhood_sizedistances_mesh_temp = mod(neigh_x_mesh,1) + traj_mesh;
% 			distances = distances_mesh_temp(:);
% 			
% 			[traj_mesh neigh_y_mesh] = meshgrid(obj.reconMatrixSize(2)*traj(:,2),neighbors_y);
% 			voxel_y_mesh = round(neigh_y_mesh + traj_mesh);
% 			distances_mesh_temp = mod(neigh_y_mesh,1) + traj_mesh;
% 			distances(:,2) = distances_mesh_temp(:);
% 			
% 			[traj_mesh neigh_z_mesh] = meshgrid(obj.reconMatrixSize(3)*traj(:,3),neighbors_z);
% 			voxel_z_mesh = round(neigh_z_mesh + traj_mesh);
% 			distances_mesh_temp = mod(neigh_z_mesh,1) + traj_mesh;
% 			distances(:,3) = distances_mesh_temp(:);
% 			distances = distances';

			
% 			[sample_idx,voxel_idx,distances] = ...
% 				sparse_gridding_distance_mex(traj',...
% 				obj.neighborhoodSize,...
% 				uint32(obj.reconMatrixSize'));
			
			%% L-2 Norm calcualtions
			% L-2 Norm
			distances = sqrt(sum(distances.^2,1));
			
			% Only include samples within bounds
			idxOutOfBounds = (abs(distances) > 0.5*obj.neighborhoodSize);
			
			% Remove all data not in bounds
			sample_idx(idxOutOfBounds) = [];
			voxel_idx(idxOutOfBounds) = [];
			distances(idxOutOfBounds) = [];
			
			% Calculate kernel values
			[kernel_vals]=KaiserBesselKernel(obj.neighborhoodSize,...
				obj.overgridFactor, distances);
			
			% 			%% L=1 Norm calculations
			% 			nDim = size(distances,1);
			% 			for iDim = 1:nDim
			% 				% Only include samples within bounds
			% 				idxOutOfBounds = (distances(iDim,:) > 0.5*obj.neighborhoodSize);
			%
			%
			% 				% Remove all data not in bounds
			% 				sample_idx(:,idxOutOfBounds) = [];
			% 				voxel_idx(:,idxOutOfBounds) = [];
			% 				distances(:,idxOutOfBounds) = [];
			% 			end
			% 			kernel_vals = ones([1,size(distances,2)]);
			% 			for iDim = 1:nDim
			% 				% Calculate kernel values
			% 				kernel_vals=kernel_vals.*KaiserBesselKernel(...
			% 					obj.neighborhoodSize, obj.overgridFactor, ...
			% 					distances(iDim,:));
			% 			end
			
			% Create sparse system matrix;
			idxNonSparse = ((kernel_vals ~= 0) & (sample_idx ~= 0) & (voxel_idx ~= 0));
			sample_idx = sample_idx(idxNonSparse);
			voxel_idx = voxel_idx(idxNonSparse);
			% 			distances = distances(idxNonSparse);
			kernel_vals = kernel_vals(idxNonSparse);
			obj.A = sparse(sample_idx,voxel_idx,kernel_vals,size(traj,1),...
				prod(obj.reconMatrixSize));
		end
		
		function reconVol = imageSpace(obj, reconVol)
			reconVol = imageSpace@SystemModel(obj,reconVol);
			
			%  Shift data by fov/4
			% 			reconVol = circshift(reconVol,round(0.5*(obj.reconMatrixSize-obj.outputImageSize)));
			reconVol = circshift(reconVol,0.5*obj.outputImageSize);
			
			% Crop BL corner
			reconVol = reconVol(1:obj.outputImageSize(1),...
				1:obj.outputImageSize(2), ...
				1:obj.outputImageSize(3));
		end
		
		function true_false = isCompatible(obj,traj,header,overgridfactor,nNeighbors);
			true_false = false;
		end
	end
end