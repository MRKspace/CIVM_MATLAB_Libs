%KAISERBESSELKERNELGENERATOR   Creates a Kaiser Bessel kernel.
%   KAISERBESSELKERNELGENERATOR(filter_dims, fermi_scale, fermi_width) 
%   creates a Kaiser Bessel function from 0-kernel_width. Jackson et al 
%   showed that the Kaiser Bessel function is a good approximation to the
%   prolate spheroidal wave function. (Selection of a Convolution Function 
%   for Fourier Inversion using Gridding. Jackson et al. 1991.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/07/19 $
function [kernel_val]=KaiserBesselKernel(w,a,kernel_dist)
%Calculate Beta value (Rapid Gridding Reconstruction With a Minimal Oversampling Ratio. Beatty et al. 2005.)
b = pi*sqrt( ((w/a)*(a-0.5))^2-0.8 );

% Calculate Kaiser Bessel Function
x = b*sqrt(1-(2*kernel_dist/w).^2);
kernel_val = besseli(0,x)./w;
kernel_val = kernel_val/max(kernel_val(:)); %Normalize
