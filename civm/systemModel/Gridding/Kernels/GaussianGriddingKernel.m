classdef GaussianGriddingKernel < GriddingKernel
	properties
		kernel_width;
		overgrid_factor;
		sigma;
		unique_string;
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
						
			% Fill in unique string
			obj.unique_string = ['gaussian_idth' num2str(obj.kernel_width) ...
				'_overgrid' num2str(obj.overgrid_factor) '_sigma' num2str(obj.sigma)];
		end
		
		function [kernel_vals] = kernelValues(obj, distances)
			% Calculate Gaussian Function
			kernel_vals = exp(-0.5*(distances/sigma).^2)
			
			%Normalize
			kernel_vals = kernel_vals/max(kernel_vals(:));
% 			kernel_vals = kernel_vals/sum(kernel_vals(:)); % seems better than max...  
		end
	end
end