%CALCDCF_Analytical   Calculates the density compensation of each trajectory
%   point based on analyytical estimation. 
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2013/02/01 $
function dcf = calcDCF_Analytical(recon_data, header)
    dcf = sqrt(recon_data.Traj(1,:).^2 + recon_data.Traj(2,:).^2 + ...
        recon_data.Traj(3,:).^2);
    
    dcf = dcf/(max(dcf));
    dcf = dcf.*dcf;
end