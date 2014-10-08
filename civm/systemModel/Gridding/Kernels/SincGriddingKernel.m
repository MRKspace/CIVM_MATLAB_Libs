classdef SincGriddingKernel < GriddingKernel
	properties
		kernel_width;
		overgrid_factor;
	end
	
	methods
		% Constructor
		function obj = SincGriddingKernel(kernWidth, overgridFactor, verbose)
			% Call super constructor to build obj
			obj = obj@GriddingKernel(verbose);
			
			% Store properties
			obj.kernel_width = kernWidth;
			obj.overgrid_factor = overgridFactor;
						
			% Fill in unique string
			obj.unique_string = ['sinc_idth' num2str(obj.kernel_width) ...
				'_overgrid' num2str(obj.overgrid_factor)];
		end
		
		function [kernel_vals] = kernelValues(obj, distances)
		
			% Calculate sinc Function
			kernel_vals = sin(2*pi*distances)./(2*pi*distances);
			kernel_vals(distances==0)=1;
			
			%Normalize
			kernel_vals = kernel_vals/max(kernel_vals(:));
% 			kernel_vals = kernel_vals/sum(kernel_vals(:)); % seems better than max...  
		end
	end
end