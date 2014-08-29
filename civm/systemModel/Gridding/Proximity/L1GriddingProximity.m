classdef L1GriddingProximity < GriddingProximity
	properties
		verbose;
	end
	
	methods
		function obj = L1GriddingProximity(kernelObj, verbosity)
			% Call super constructor to build obj
			obj = obj@GriddingProximity(kernelObj);
			
			% Save properties of object
			obj.verbose = verbosity;
			obj.unique_string = 'L1';
		end

		function [kernel_vals idxOutOfBounds] = kernelValues(obj, distances, neighborhoodSize)
			% Look for any values that are still out of bounds
			idxOutOfBounds = any(abs(distances) > 0.5*neighborhoodSize);
			
			% Calculate kernel values
			nDims = size(distances,1);
			kernel_vals = ones([1 size(distances,2)]);
			for iDim = 1:nDims
				kernel_vals = kernel_vals.*obj.kernelObj.kernelValues(distances(iDim,:));
			end
		end
	end
end