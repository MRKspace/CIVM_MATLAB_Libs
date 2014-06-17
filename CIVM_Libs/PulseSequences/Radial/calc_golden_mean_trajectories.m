%% Calculates 3D radial trajectories based on the 2D golden means.
% The 2D golden means are : 0.4656 and 0.6823
% % S. Sivaram Kaushik,2013

function kspace_traj = calc_golden_mean_trajectories(nframes,rad)

i = 0:nframes-1;
pi_double = 3.141592653589793116;

phi1 = 0.4655;
phi2 = 0.6823;

tempa= mod(i.*phi2,1);
tempb= mod(i.*phi1,1);

alpha = 2*pi_double.* tempa;
beta = acos(2*tempb-1); % Between pos/neg 1

% csv_file = filepath('/home/scott/Desktop/gradscale_files/gradscalefile_golden_7000.txt');
% traj = csvread(csv_file);
% 
% dx = traj(1:nframes,1)';
% dy = traj(1:nframes,2)';
% dz = traj(1:nframes,3)';

dx = cos(alpha).*sin(beta);
dy = sin(alpha).*sin(beta);
dz = cos(beta);

kx = rad*dx;
ky = rad*dy;
kz = rad*dz;
kspace_traj(1,:) = kx(:);
kspace_traj(2,:) = ky(:);
kspace_traj(3,:) = kz(:);
