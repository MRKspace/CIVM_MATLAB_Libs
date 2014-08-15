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
			[sample_idx,voxel_idx,distances] = ...
				sparse_gridding_distance_mex(traj',...
				obj.neighborhoodSize,...
				uint32(obj.reconMatrixSize'));
			distances = sqrt(distances);
			
			% Calculate kernel values
			[kernel_vals]=KaiserBesselKernel(obj.neighborhoodSize,...
				obj.overgridFactor, distances);
			
			% Create sparse system matrix;
			nonzero_idx = ~((sample_idx == 0) & (distances == 0) & (voxel_idx == 0));
			sample_idx = sample_idx(nonzero_idx);
			voxel_idx = voxel_idx(nonzero_idx);
			distances = distances(nonzero_idx);
			kernel_vals = kernel_vals(nonzero_idx);
			obj.A = sparse(sample_idx,voxel_idx,kernel_vals,size(traj,1),...
				prod(obj.reconMatrixSize));
		end
		
		function true_false = isCompatible(obj,traj,header,overgridfactor,nNeighbors);
			true_false = false;
		end
	end
end