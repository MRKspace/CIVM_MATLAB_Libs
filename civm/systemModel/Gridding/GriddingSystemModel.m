classdef GriddingSystemModel < SystemModel
	properties
		outputImageSize;
		overgridFactor;
		neighborhoodSize;
		kaiser_b;
		proximetyObj;
		verbose;
	end
	methods
		function obj = GriddingSystemModel(traj, samp_snr, output_image_size, ...
				overgrid_factor, neighborhood_size, proxObj, verbosity)
			
			% Initialize properties
			obj.outputImageSize = output_image_size;
			obj.overgridFactor = overgrid_factor;
			obj.neighborhoodSize = neighborhood_size;
			obj.reconMatrixSize = ceil(output_image_size * overgrid_factor);
			obj.proximetyObj = proxObj;
			obj.unique_string = ['griddingModel_' proxObj.unique_string];
			obj.verbose = verbosity;
			
			% Calculate gridding distances
			if(obj.verbose)
				disp('Calculating distances...');
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
				obj.neighborhoodSize,...
				uint32(obj.reconMatrixSize'));
			if(obj.verbose)
				disp('Finished calculating distances.');
			end
			
			%Apply proximity info
			if(obj.verbose)
				disp('Calculating kernel values...');
			end
			[kernel_vals keepData] = obj.proximetyObj.kernelValues(distances);
			if(obj.verbose)
				disp('Finished calculating kernel values.');
			end
			clear distances;
			
			keepData = keepData&((kernel_vals ~= 0) & (sample_idx > 0) & (voxel_idx > 0));
			
			% Remove all data not in bounds
			tmpStore = kernel_vals(keepData); % Do this first since its complex
			kernel_vals = tmpStore;
			
			tmpStore = sample_idx(keepData);
			sample_idx = tmpStore;
			
			tmpStore = voxel_idx(keepData);
			clear keepData;
			voxel_idx = tmpStore;
			clear tmpStore;
			
			% Create sparse system matrix;			
			obj.A = sparse(sample_idx,voxel_idx,kernel_vals,size(traj,1),...
				prod(obj.reconMatrixSize),length(sample_idx));
			
% 			% Figure out the weighting of each voxel
% 			vox_weight = full(sum(obj.A,1));
% 			n = length(vox_weight);
% 			vox_weight = spdiags(1./vox_weight(:),0,n,n);
% 			obj.A = obj.A*vox_weight;
		end
		
		function reconVol = imageSpace(obj, reconVol)
			reconVol = imageSpace@SystemModel(obj,reconVol);
			
			% center the DC freq
			reconVol = fftshift(reconVol);
			
			% Deapodize
			reconVol = obj.proximetyObj.deapodize(reconVol,obj.reconMatrixSize);
			
			% Uncenter the DC freq
			reconVol = fftshift(reconVol);
			
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