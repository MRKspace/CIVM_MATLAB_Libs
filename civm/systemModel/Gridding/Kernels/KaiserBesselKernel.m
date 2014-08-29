%KAISERBESSELKERNELGENERATOR   Creates a Kaiser Bessel kernel.
%   KAISERBESSELKERNELGENERATOR(filter_dims, fermi_scale, fermi_width)
%   creates a Kaiser Bessel function from 0-kernel_width. Jackson et al
%   showed that the Kaiser Bessel function is a good approximation to the
%   prolate spheroidal wave function. (Selection of a Convolution Function
%   for Fourier Inversion using Gridding. Jackson et al. 1991.
%
%   Choice of Beta from "Rapid Gridding Reconstruction with a minimal
%   Oversampling ratio" Beaty et all IEEE 2005.
%
%   w = kernel width (in overgrid units)
%   a = overgridfactor
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/07/19 $
classdef KaiserBesselGriddingKernel < GriddingKernel
	properties
		kernel_width;
		overgrid_factor;
		beta;
		unique_string;
	end
	
	methods
		% Constructor
		function obj = KaiserBesselGriddingKernel(kernWidth, overgridFactor, betaOverride)
			% Call super constructor to build obj
			obj = obj@GriddingKernel();
			
			% Store properties
			obj.kernel_width = kernWidth;
			obj.overgrid_factor = overgridFactor;
			
			%Calculate Beta value (Rapid Gridding Reconstruction With a Minimal Oversampling Ratio. Beatty et al. 2005.)
			if(isempty(kaiser_b_override))
				obj.beta = pi*sqrt( ((obj.kernel_width/obj.overgrid_factor)*...
					(obj.overgrid_factor-0.5))^2-0.8 );
			else
				obj.beta = betaOverride;
			end
			
			% Fill in unique string
			obj.unique_string = ['kaiserWidth' num2str(obj.kernel_width) ...
				'overgrid' num2str(obj.overgrid_factor) 'beta' num2str(obj.beta)];
		end
		
		function [kernel_vals idxOutOfBounds] = ...
				kernelValues(obj, distances, neighborhoodSize);
			% Calculate Kaiser Bessel Function
			kernel_vals = besseli(0,kaiser_b*sqrt(1-(2*kernel_dist/w).^2));
			
			%Normalize
			kernel_vals = kernel_vals/max(kernel_vals(:));
% 			kernel_vals = kernel_vals/sum(kernel_vals(:)); % seems better than max...  
		end
	end
end