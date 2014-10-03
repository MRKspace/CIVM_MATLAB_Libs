classdef GriddingProximity
	properties
		kernelObj;
		unique_string;
	end
	
	methods
		function obj = GriddingProximity(kernObj)
			% Save properties to object
			obj.kernelObj = kernObj;
		end
	end
	
	methods (Abstract)
		[kernel_vals idxOutOfBounds] = kernelValues(obj, distances);
		[reconVol] = deapodize(obj, reconVol, outputSize);
	end
end