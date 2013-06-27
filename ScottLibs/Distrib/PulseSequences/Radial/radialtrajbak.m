%CALC_RADIAL_TRAJ_DISTANCE   Calculates radial sampling.
%   CALC_RADIAL_TRAJ_DISTANCE(header) calculates the radial sampling 
%   defined by the scan parmeters (receiver BW, t_off, tramp, npts, etc).
%   Returns the radial distances, as well as the gradients, and ideal 
%   radial distances (distance assuming gradients turn on instantaneously).
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/07/19 $
function [rad_dist, gradient_dist, ideal_dist] = calc_radial_traj_distance(header)
% Pull relevant info from header
bw = header.rdb.rdb_hdr_user12;                 % Receiver bandwidth
grad_delay_time = header.rdb.rdb_hdr_user22    % Time between ADC on and start of gradient ramp
% grad_delay_time = 0.1; %header.rdb.rdb_hdr_user22;    % Time between ADC on and start of gradient ramp
% grad_delay_time = 0.06; %header.rdb.rdb_hdr_user22;    % Time between ADC on and start of gradient ramp
% grad_delay_time = 0.132; % Shivs magic number that I dont understand
ramp_time = header.rdb.rdb_hdr_user1;           % Time to ramp gradients
npts = header.rdb.rdb_hdr_frame_size;           % Number of sample points per frame/ray

%Calculate times
delta_t = 1/(2*bw);                                             % Time between each sample
total_t = npts * delta_t;                                       % Total time per ray
grad_plateau_time = total_t - (ramp_time + grad_delay_time);    % Time in plateau
t = linspace(0,total_t,npts)';                                  % Time vector

%Calculate the max amplitude,G, needed to end up at a radius of 0.5 for ideal case
G = 0.5/(grad_plateau_time+0.5*ramp_time);

% Calculate binary masks for each time region
in_ramp = (t>grad_delay_time).*(t<(grad_delay_time+ramp_time)); % Binary mask for times in ramp
in_plateau = (t>=grad_delay_time+ramp_time);                    % Binary mask for times in plateau

% Calculate times in each region
ramp_t = (t - grad_delay_time).*in_ramp;                        % Time from start of ramp
plateau_t = (t - (grad_delay_time + ramp_time)).*in_plateau;    % Time from start of plateau

%Calculate the amplitude of G over time
ramp_g = ramp_t*(G/ramp_time);  % "gradient" amplitude in ramp
plateau_g = G.*in_plateau;      % "gradient" amplitude in plateau
gradient_dist = ramp_g + plateau_g;

% Calculate radial position from piecewise area calculations
ramp_dist = 0.5.*ramp_t.*ramp_g;                                    % Trajectory distance in ramp
plateau_dist = plateau_t.*plateau_g + 0.5*ramp_time*G.*in_plateau;  % Trajectory distance in plateau
rad_dist = ramp_dist + plateau_dist;                                % Trajectory distance

ideal_dist = G*t;

% Plotting - for debug purposes
figure();
hold on;
plot(t,gradient_dist,'.r');
plot(t,rad_dist,'.b');
hold off;
legend('Gradient','Radial Trajectory Distance');
xlabel('Time (or sample number)');



