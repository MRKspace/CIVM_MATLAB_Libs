%CALC_ARCHIMEDIAN_SPIRAL_TRAJECTORIES   Archimedian spiral trajectory generator.
%   CALC_ARCHIMEDIAN_SPIRAL_TRAJECTORIES(nframes, primeplus, rad) calculates
%   the radial trajectories following an archimedial spiral. nframes defines
%   the number of frames, primeplus defines the randomizing allong the 
%   spiral, and rad defines the radial sample locations. This is a 
%   slightly modified version of a vectorized version provided by 
%   Sam Johnston.
%
%   Authors: Gary Cofer, Sam Johnston, Scott Haile Robertson.
%   $Revision: 1.0 $  $Date: 2012/07/19 $
function kspace_traj = calc_archimedian_spiral_trajectories(nframes, primeplus, rad)
% nframes=floor(nframes/2)*2+1; %Must have odd number of frames
cview=floor(nframes/2)+1;     %Center frame 
kspace_traj=zeros(3,length(rad)*nframes);

is = 0:nframes-1; %In Gary's code, i=acview_start

z_coords = abs(1-(is/cview)); %In Gary's code f=fThing
angs = primeplus.*is.*(pi/180); %Angle in radians
ds = sqrt(1-(z_coords.^2));
x_coords = ds.*cos(angs);
y_coords = ds.*sin(angs);

%Handle negatives
z_coords = z_coords.*((2*(is<=cview))-1);

%normalize
ivec_lengths = 1./sqrt((x_coords.^2) + (y_coords.^2) + (z_coords.^2));
xs = x_coords.*ivec_lengths;
ys = y_coords.*ivec_lengths;
zs = z_coords.*ivec_lengths;

thetas = acos(zs);
phis = atan2(y_coords,x_coords);

dx = (sin(thetas).*cos(phis));
dy = (sin(thetas).*sin(phis));
dz = (cos(thetas));

% i_amp = 9883;
% temp = floor(i_amp*[dx;dy;dz]')/i_amp;
% load('gradscales.mat');
% gradscales(:,3) = floor(i_amp*gradscales(:,3).*((2*(is'<=cview))-1))/i_amp;
% % plot3(gradscales(:,1),gradscales(:,2),gradscales(:,3),'.r');
% % hold on;
% % plot3(temp(:,1),temp(:,2),temp(:,3),'.b');
% % hold off;
% 
% diff_scales = gradscales - temp;
% % figure();
% % plot(diff_scales(:,1),'-r');
% % hold on;
% % plot(diff_scales(:,2),'-g');
% % plot(diff_scales(:,3),'-b');
% % hold off;
% % legend('X error','Y error','Z error');
% % xlabel ('View number');
% % ylabel('Error');
% 
% % override calculated values
% dx = gradscales(:,1)';
% dy = gradscales(:,2)';
% dz = gradscales(:,3)';

kx = rad*dx; %x-coordinates of rays
ky = rad*dy; %y-coordinates of rays
kz = rad*dz; %z-coordinates of rays

kspace_traj(1,:) = kx(:);
kspace_traj(2,:) = ky(:);
kspace_traj(3,:) = kz(:);

