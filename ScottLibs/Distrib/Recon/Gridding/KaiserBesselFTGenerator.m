%KAISERBESSELFTGENERATOR   Calculates the FT of Kaiser Bessel kernel.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2013/07/24 $
function [fft_kb, mask]=KaiserBesselFTGenerator(w,a, output_sz)
%Calculate Beta value (Rapid Gridding Reconstruction With a Minimal Oversampling Ratio. Beatty et al. 2005.)
b = pi*sqrt( ((w/a)*(a-0.5))^2-0.8 );

hw1 = (output_sz(1)-1)/(2*output_sz(1));
hw2 = (output_sz(2)-1)/(2*output_sz(2));
hw3 = (output_sz(3)-1)/(2*output_sz(3));

xlsp = linspace(-hw1,hw1, output_sz(1));
ylsp = linspace(-hw2,hw2, output_sz(2));
zlsp = linspace(-hw3,hw3, output_sz(3));

[x y z] = meshgrid(xlsp,ylsp,zlsp);
r = sqrt(x.^2 + y.^2 + z.^2);
mask = r <= 0.5;
r(r>0.5)=0.5;
clear x y z;

fft_kb = sin(sqrt((pi*w*r).^2-b^2))./sqrt((pi*w*r).^2-b^2);


