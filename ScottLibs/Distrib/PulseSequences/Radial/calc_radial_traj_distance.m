%CALC_RADIAL_TRAJ_DISTANCE   Calculates radial sampling.
%   CALC_RADIAL_TRAJ_DISTANCE(header) calculates the radial sampling 
%   defined by the scan parmeters (receiver BW, t_off, tramp, npts, etc).
%   Returns the radial distances, as well as the gradients, and ideal 
%   radial distances (distance assuming gradients turn on instantaneously).
%
%   Scale 0 to 1
%   
%   This code should exactly duplicate the trajectories calculated by
%   radish, allowing for a fair comparison of the two reconstructions. The
%   radish trajectories are calculated withing:
%   /Volumes/recon_home/script/dir_radish/modules/source/proj3d_GHG/source/3dpr10_sg09.c
%   and are used with compiled code:
%   /Volumes/recon_home/script/dir_radish/modules/bin_macINTEL/grid3d01_do_all
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/07/19 $
function [rad_dist, gradient_dist, ideal_dist] = calc_radial_traj_distance(header)
% Pull relevant info from header
bw = header.rdb.rdb_hdr_user12;                 % Receiver bandwidth
grad_delay_time = header.rdb.rdb_hdr_user22;    % Time between ADC on and start of gradient ramp
ramp_time = header.rdb.rdb_hdr_user1;           % Time to ramp gradients
npts = header.rdb.rdb_hdr_frame_size;           % Number of sample points per frame/ray

delta_t = 1/(2*bw);                                             % Time between each sample
total_t = npts * delta_t;                                       % Total time per ray

% If NUFFT, add 1.5 extra dwell points to toff due to pulse sequence fix
% for mandy's recon
if(header.rdb.rdb_hdr_user21 == 1400)
    grad_delay_time = grad_delay_time + 1.5*delta_t;
end

% Shivs magic number... no clue why
% grad_delay_time = 0.132;

% Put everything in pixel units rather than time
grad_delay_time = npts*grad_delay_time/total_t;
ramp_time = npts*ramp_time/total_t;

%Calculate times

grad_plateau_time = npts - (ramp_time + grad_delay_time);    % Time in plateau
t = [0:(npts-1)]';                                       % Time vector

% %Calculate the max amplitude,G, needed to end up at a radius of 0.5 for
% %ideal case (gradient turn on immediately with no ramp)
% G = 1/(total_t);%G = 0.5/(grad_plateau_time+ramp_time);

% Calculate binary masks for each time region
in_ramp = (t>grad_delay_time).*(t<(grad_delay_time+ramp_time)); % Binary mask for times in ramp
in_plateau = (t>=grad_delay_time+ramp_time);                    % Binary mask for times in plateau

% Calculate times in each region
ramp_t = (t - grad_delay_time).*in_ramp;                        % Time from start of ramp
plateau_t = (t - (grad_delay_time + ramp_time)).*in_plateau;    % Time from start of plateau

%Calculate the amplitude of G over time
ramp_g = ramp_t/ramp_time;  % "gradient" amplitude in ramp
plateau_g = in_plateau;      % "gradient" amplitude in plateau
gradient_dist = ramp_g + plateau_g;

% Calculate radial position from piecewise area calculations
ramp_dist = 0.5*ramp_t.*ramp_g;                                    % Trajectory distance in ramp
plateau_dist = plateau_t.*plateau_g + 0.5*ramp_time*in_plateau;  % Trajectory distance in plateau
rad_dist = ramp_dist + plateau_dist;                                % Trajectory distance

rad_dist = rad_dist/npts;

ideal_dist = t;

% % Plotting - for debug purposes
% figure();
% hold on;
% plot(t,gradient_dist,'.r');
% plot(t,rad_dist,'.b');
% hold off;
% legend('Gradient','Radial Trajectory Distance');
% xlabel('Time (or sample number)');



