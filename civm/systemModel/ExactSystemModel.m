classdef ExactSystemModel < SystemModel
	properties
		outputImageSize;
	end
	methods
		function obj = ExactSystemModel(traj, output_image_size)
			
			% Initialize properties
			obj.outputImageSize = output_image_size;
			obj.reconMatrixSize = output_image_size;
			
			% Initialize NUFFT Model
			nufft = Gmri(traj, ...
				true(obj.outputImageSize), ...
				'fov', obj.outputImageSize, ...
				'exact', 1,'n_shift',round(0.5*obj.outputImageSize));
			
			obj.A = nufft;
		end
		
		function reconVol = imageSpace(obj, reconVol)
			reconVol = reconVol;
		end
		
		function true_false = isCompatible(obj,traj,header,overgridfactor,nNeighbors);
			true_false = false;
		end
	end
end