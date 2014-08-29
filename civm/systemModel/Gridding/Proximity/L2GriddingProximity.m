classdef L2GriddingProximity < GriddingProximity
	properties
		verbose;
	end
	
	methods
		function obj = L2GriddingProximity(kernelObj, verbosity)
			% Call super constructor to build obj
			obj = obj@GriddingProximity(kernelObj);
			
			% Save properties of object
			obj.unique_string = 'L2';
			obj.verbose = verbosity;
		end

		function [kernel_vals idxOutOfBounds] = kernelValues(obj, distances, neighborhoodSize)
			% Calculate L2 distances
			if(obj.verbose)
				disp('Calculating L2 distances...');
			end
			distances = sqrt(sum(distances.^2,1));
			if(obj.verbose)
				disp('Finished calculating L2 distances.');
			end
			
			% Look for any values that are still out of bounds
			idxOutOfBounds = abs(distances) > 0.5*neighborhoodSize;
			
			% Calculate kernel values
			kernel_vals = obj.kernelObj.kernelValues(distances);
		end
	end
end