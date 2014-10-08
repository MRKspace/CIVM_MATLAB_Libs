classdef ExactSystemModel < SystemModel
	properties
		outputImageSize;
		overgridFactor;
	end
	methods
		function obj = ExactSystemModel(traj, overgrid_factor, output_image_size)
			
			% Initialize properties
			obj.overgridFactor = overgrid_factor;
			obj.outputImageSize = output_image_size;
			obj.reconMatrixSize = output_image_size*obj.overgridFactor;
						
			% Initialize NUFFT Model
			nufft = Gmri(traj, ...
				true(obj.reconMatrixSize), ...
				'fov', obj.reconMatrixSize, ...
				'exact', 1,'n_shift',round(0.5*obj.reconMatrixSize));
			
			obj.A = nufft;
		end
		
		function obj = imageSpace(obj, reconVol)
			obj.reconVol = obj.reconVol;
			warning('You need to crop!');
		end
		
		function true_false = isCompatible(obj,traj,header,overgridfactor,nNeighbors);
			true_false = false;
		end
	end
end