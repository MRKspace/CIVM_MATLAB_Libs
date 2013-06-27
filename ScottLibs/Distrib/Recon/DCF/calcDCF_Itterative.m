%CALCDCF_Itterative   Calculates the density compensation of each
%   trajectory point based on itterative estimation.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2013/02/13 $
function dcf = calcDCF_Itterative(coords,overgridfactor,image_size_dcf,...
    num_dcf_itter,dcf_init)
if(nargin < 6)
    dcf_init = ones(1, size(coords,2));
end

% Itterative DCF calculation
dcf = sdc3_MAT(coords,num_dcf_itter,image_size_dcf,0,overgridfactor,...
    dcf_init)';
end