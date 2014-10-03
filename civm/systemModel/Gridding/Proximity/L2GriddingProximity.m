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

		function [kernel_vals idxInBounds] = kernelValues(obj, distances)
			% Calculate L2 distances
			if(obj.verbose)
				disp('Calculating L2 distances...');
			end
			% same as sqrt(sum(distances.^2,1))
			[nDim nDist] = size(distances);
			l2_dist = ones([1 nDist]);
			kernel_vals = ones([1 nDist]);
			for(iDim = 1:nDim)
				l2_dist = distances(iDim,:);
				l2_dist = l2_dist.^2;
				kernel_vals = kernel_vals.*l2_dist;
			end
			l2_dist = sqrt(kernel_vals);
			if(obj.verbose)
				disp('Finished calculating L2 distances.');
			end
			
			% Look for any values that are still out of bounds
			idxInBounds = l2_dist < 0.5*obj.kernelObj.kernel_width;
			
			% Calculate kernel values
			kernel_vals = obj.kernelObj.kernelValues(l2_dist);
		end
		
		function [reconVol] = deapodize(obj, reconVol, outputSize)
			lsp = abs([1:(outputSize(1))] - 0.5*outputSize(1) - 1)/obj.kernelObj.overgrid_factor;
			
			[x y z] = meshgrid(lsp,lsp,lsp);
			r = sqrt(x.^2 + y.^2 + z.^2);
			clear x y z;

			sz = size(r);
			[kspace_kern mask] = obj.kernelValues(r(:)');
			clear r;
			kspace_kern = reshape(kspace_kern.*~mask,sz);
			clear mask;
			deapFunc = ifftshift(ifftn(kspace_kern));
			nearlyZeroVal = (abs(deapFunc) < max(abs(deapFunc(:)))*10E-3);
			clear kspace_kern;
			
			reconVol(~nearlyZeroVal) = reconVol(~nearlyZeroVal)./deapFunc(~nearlyZeroVal);
		end
	end
end