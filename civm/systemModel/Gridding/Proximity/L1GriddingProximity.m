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
			obj.unique_string = ['L1' kernelObj.unique_string];
		end

		function [kernel_vals idxOutOfBounds] = kernelValues(obj, distances)
			% Look for any values that are still out of bounds
			idxOutOfBounds = any(abs(distances) > 0.5*obj.kernelObj.kernel_width);
			
			% Calculate kernel values
			nDims = size(distances,1);
			kernel_vals = ones([1 size(distances,2)]);
			for iDim = 1:nDims
				kernel_vals = kernel_vals.*obj.kernelObj.kernelValues(distances(iDim,:));
			end
		end
		
		function [reconVol] = deapodize(obj, reconVol, outputSize)
			lsp = abs([1:outputSize(1)] - 0.5*outputSize(1) - 1);
			[x y z] = meshgrid(lsp,lsp,lsp);
			clear lsp;
			
			sz = size(x);
			xyz = [x(:)'; y(:)'; z(:)'];
			clear x y z;
			[kspace_kern mask] = obj.kernelValues(xyz);
			kspace_kern = reshape(kspace_kern.*~mask,sz);
			clear mask;
			deapFunc = ifftshift(ifftn(kspace_kern));
			
			reconVol = reconVol./deapFunc;
		end
	end
end