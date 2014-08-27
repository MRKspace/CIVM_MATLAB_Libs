classdef NufftSystemModel < SystemModel
	properties
		outputImageSize;
		overgridFactor;
		neighborhoodSize;
	end
	methods
		function obj = NufftSystemModel(traj, output_image_size, ...
				overgrid_factor, neighborhood_size)
			
			% Initialize properties
			obj.outputImageSize = output_image_size;
			obj.overgridFactor = overgrid_factor;
			obj.neighborhoodSize = neighborhood_size;
			obj.reconMatrixSize = output_image_size * overgrid_factor;
			
			% Initialize NUFFT Model
			nufft = Gmri(traj, ...
				true(obj.outputImageSize), ...
				'fov', obj.outputImageSize, ...
				'nufft_args', ...
				{obj.outputImageSize, ...
				obj.neighborhoodSize, ...
				obj.reconMatrixSize, ...
				obj.outputImageSize/2,...
				'minmax:kb'});
			
			obj.A = nufft.arg.Gnufft.arg.st.p;
		end
		
		function reconVol = imageSpace(obj, reconVol)
			reconVol = imageSpace@SystemModel(obj,reconVol);
			
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