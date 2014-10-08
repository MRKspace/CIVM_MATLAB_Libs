classdef L2GriddingProximity < GriddingProximity
	properties
		verbose;
	end
	
	methods
		function obj = L2GriddingProximity(kernelObj, verbosity)
			% Call super constructor to build obj
			obj = obj@GriddingProximity(kernelObj);
			
			% Save properties of object
			obj.unique_string = ['L2' kernelObj.unique_string];
			obj.verbose = verbosity;
		end

		function [system_matrix] = kernelValues(obj, traj,...
				kernel_extent,...
				reconMatrixSize,...
				overgridFactor)
						% Calculate gridding distances
			if(obj.verbose)
				disp('Calculating L2 distances...');
			end
% 			neigh_size = 0.5*(neighborhood_size*overgrid_factor-1);
% 			neighbor_lsp = [-neigh_size:neigh_size];
% 			[neighbors_x neighbors_y neighbors_z] = meshgrid(neighbor_lsp, ...
% 				neighbor_lsp, neighbor_lsp);
% 			neighbors_x = neighbors_x(:);
% 			neighbors_y = neighbors_y(:);
% 			neighbors_z = neighbors_z(:);
% 			
% 			
% 			[sample_idx, junk] = meshgrid(1:size(traj,1),neighbors_x); 
% 			clear junk;
% 			sample_idx = sample_idx(:)';			
% 			
% 			[traj_x_mesh neigh_x_mesh] = meshgrid(obj.reconMatrixSize(1)*traj(:,1),neighbors_x);
% 			clear neighbors_x;
% 			delta_x_mesh = mod(traj_x_mesh + 0.5,1) - 0.5 + neigh_x_mesh;
% 			distances(1,:) = delta_x_mesh(:);
% 			clear delta_x_mesh;
% 			vox_x_mesh = mod(round(traj_x_mesh + neigh_x_mesh), obj.reconMatrixSize(1)) + 1;
% 			clear neigh_x_mesh traj_x_mesh;
% 			
% 			[traj_y_mesh neigh_y_mesh] = meshgrid(obj.reconMatrixSize(2)*traj(:,2),neighbors_y);
% 			clear neighbors_y;
% 			delta_y_mesh = mod(traj_y_mesh + 0.5,1) - 0.5 + neigh_y_mesh;
% 			distances(2,:) = delta_y_mesh(:);
% 			clear delta_y_mesh;
% 			vox_y_mesh = mod(round(traj_y_mesh + neigh_y_mesh), obj.reconMatrixSize(2)) + 1;
% 			clear neigh_y_mesh traj_y_mesh;
% 			
% 			
% 			
% 			[traj_z_mesh neigh_z_mesh] = meshgrid(obj.reconMatrixSize(3)*traj(:,3),neighbors_z);
% 			clear neighbors_z;
% 			delta_z_mesh = mod(traj_z_mesh + 0.5,1) - 0.5 + neigh_z_mesh;
% 			distances(3,:) = delta_z_mesh(:);
% 			clear delta_z_mesh;
% 			vox_z_mesh = mod(round(traj_z_mesh + neigh_z_mesh), obj.reconMatrixSize(3)) + 1;
% 			clear neigh_z_mesh traj_z_mesh;
% 			
% 	
% 			voxel_idx = sub2ind(obj.reconMatrixSize,vox_x_mesh,vox_y_mesh,vox_z_mesh);
% 			clear vox_x_mesh vox_y_mesh vox_z_mesh;
% 			voxel_idx = voxel_idx(:)';
% 						
% 			% Convert to image space distances
% 			distances = distances/overgrid_factor;
			
			[sample_idx,voxel_idx,distances] = ...
				sparse_gridding_distance_mex(traj',...
				kernel_extent,...
				uint32(reconMatrixSize'));
			if(obj.verbose)
				disp('Finished calculating L2 distances.');
			end
			
			if(obj.verbose)
				disp('Applying L2 Bounds...');
			end
			% Put distances in output image units
			distances = distances/overgridFactor;
			
			% Look for any values that are still out of bounds
			idxInBounds = distances <= 0.5*(kernel_extent/overgridFactor);
			sample_idx = sample_idx(idxInBounds);
			voxel_idx = voxel_idx(idxInBounds);
			distances = distances(idxInBounds);
			clear idxInBounds;
			if(obj.verbose)
				disp('Finished applying L2 Bounds...');
			end
			
			if(obj.verbose)
				disp('Applying Kernel...');
			end
			% Calculate kernel values
			kernel_vals = obj.kernelObj.kernelValues(distances);
			clear distances;
			if(obj.verbose)
				disp('Finished applying Kernel...');
			end
			
			if(obj.verbose)
				disp('Creating sparse system matrix...');
			end
			% Create sparse system matrix;			
			system_matrix = sparse(sample_idx,voxel_idx,kernel_vals,size(traj,1),...
				prod(reconMatrixSize),length(sample_idx));
			if(obj.verbose)
				disp('Finished creating sparse system matrix...');
			end
		end
		
		function [reconVol] = deapodize(obj, kernel_extent, ...
				overgridFactor, reconMatrixSize, reconVol)
			
			[sparse_kernel_kspace] = kernelValues(obj, [0 0 0],...
				kernel_extent,...
				reconMatrixSize, overgridFactor);
% 			lsp = abs([1:(outputSize(1))] - 0.5*outputSize(1) - 1)/obj.kernelObj.overgrid_factor;
% 			
% 			[x y z] = meshgrid(lsp,lsp,lsp);
% 			r = sqrt(x.^2 + y.^2 + z.^2);
% 			clear x y z;
% 
% 			sz = size(r);
% 			[kspace_kern mask] = obj.kernelValues(r(:)');
% 			clear r;
% 			kspace_kern = reshape(kspace_kern.*~mask,sz);
% 			clear mask;
			deapFunc = ifftshift(ifftn(reshape(full(sparse_kernel_kspace),reconMatrixSize)));
			nearlyZeroVal = (abs(deapFunc) < max(abs(deapFunc(:)))*10E-3);
			clear kspace_kern;
			
			reconVol(~nearlyZeroVal) = reconVol(~nearlyZeroVal)./deapFunc(~nearlyZeroVal);
		end
	end
end