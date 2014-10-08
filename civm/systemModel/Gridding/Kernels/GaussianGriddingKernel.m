classdef GaussianGriddingKernel < GriddingKernel
	properties
		kernel_width;
		overgrid_factor;
		sigma;
		norm_val;
	end
	
	methods
		% Constructor
		function obj = GaussianGriddingKernel(kernWidth, overgridFactor, sigma, verbose)
			% Call super constructor to build obj
			obj = obj@GriddingKernel(verbose);
			
			% Store properties
			obj.kernel_width = kernWidth;
			obj.overgrid_factor = overgridFactor;
			
			obj.sigma = sigma;
			
			% Calculate normalization value
			p = normcdf(-0.5*obj.kernel_width,0,obj.sigma);
			obj.norm_val = 1/(1-2*p); % needs to consider overgridding too...
						
			% Fill in unique string
			obj.unique_string = ['gaussian_width' num2str(obj.kernel_width) ...
				'_overgrid' num2str(obj.overgrid_factor) '_sigma' num2str(obj.sigma)];
		end
		
		function [kernel_vals] = kernelValues(obj, distances)
			% Calculate Normalized Gaussian Function
			kernel_vals = obj.norm_val*normpdf(distances,0,obj.sigma);
		end
	end
end