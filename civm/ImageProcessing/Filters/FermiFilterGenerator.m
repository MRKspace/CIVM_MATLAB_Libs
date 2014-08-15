%FERMIFILTERGENERATOR   3D fermi filter for image smoothing.
%   FERMIFILTERGENERATOR(filter_dims, fermi_rolloff, fermi_radius) creates a 
%   3D Fermi filter 
%   (http://en.wikipedia.org/wiki/Fermi%E2%80%93Dirac_statistics) of the 
%   same dimmensions as filter_dims, with width of fermi_width, and a 
%   scale of 1/fermi_rolloff. Note, this is memory intensive.
%
%   Default filter params:
%       -1400 fermi_rolloff=0.9, fermi_radius=0.1
%       -1700 fermi_rolloff=0.15, fermi_radius=0.75
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: July 19, 2012 $
function [fermi_filter] = FermiFilterGenerator(filter_dims,fermi_rolloff, fermi_radius)
[x y z] = meshgrid(linspace(-1,1,filter_dims(1)),...
                   linspace(-1,1,filter_dims(2)),...
                   linspace(-1,1,filter_dims(3)));
clear filter_dims;
r = sqrt(x.*x + y.*y + z.*z);
clear x y z;
fermi_filter = 1.0./(1.0+exp((1/fermi_rolloff)*(r-fermi_radius)));
clear r; % Clean up some memory