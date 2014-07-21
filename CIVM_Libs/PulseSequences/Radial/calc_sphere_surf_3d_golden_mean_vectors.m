%% Calculates an (reasonably) evenly distributed number of points on the 
% surface of a sphere
function [x, y, z] = calc_sphere_surf_3d_golden_mean_vectors(npts_on_sphere)

i = 0:npts_on_sphere-1;
golden_means = calc_golden_means(2);

alpha = 2*pi .* mod (i.*golden_means(2),1);
beta = acos(2*mod(i.*golden_means(1),1)-1);

x = (cos(alpha).*sin(beta)); %x-coordinates of rays
y = (sin(alpha).*sin(beta)); %y-coordinates of rays
z = (cos(beta)); %z-coordinates of rays

