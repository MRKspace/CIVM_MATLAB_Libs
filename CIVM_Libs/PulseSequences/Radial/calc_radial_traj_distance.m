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
bw = header.rdb.rdb_hdr_user12;                 % Receiver bandwidth (kHz)
grad_delay_time = header.rdb.rdb_hdr_user22;    % Time between ADC on and start of gradient ramp
% ramp_time = header.rdb.rdb_hdr_user1/1000;           % Time to ramp gradients
ramp_time = header.rdb.rdb_hdr_user1;           % Time to ramp gradients
npts = header.rdb.rdb_hdr_frame_size;           % Number of sample points per frame/ray
dwell_time = 1/(2*bw);                                             % Time between each sample
dwell_time = nearestMultipleOf(dwell_time,0.002); % Dwell time must be an integer multible of 2us
total_t = npts * dwell_time;                                       % Total time per ray

% If NUFFT, add 1.5 extra dwell points to toff due to pulse sequence fix
% for mandy's recon
if(header.rdb.rdb_hdr_user21 == 1400)
    grad_delay_time = grad_delay_time + 1.5*dwell_time;
end
% grad_delay_time = floor(grad_delay_time/0.004)*0.004; % gradient times must be integer multiples of 4us

% Here you need to add extra_toff_points*dwell time to the grad delay
% extra_toff_points = header.rdb.rdb_hdr_user41; % Typically 2
extra_toff_points = 0;
grad_delay_time = grad_delay_time + extra_toff_points*dwell_time
grad_delay_time = 0.084
% grad_delay_time = 0.028 % For rohan s 2T work
% load('toff.mat');
% grad_delay_time = toff
grad_delay_time

% Put everything in pixel units rather than time
grad_delay_npts = npts*grad_delay_time/total_t;
ramp_start_pt = grad_delay_npts; % Can handle negative gradient start times
grad_delay_npts = max(grad_delay_npts,0);

%Calculate ramp time based on code from EPIC
% ramp_npts = 1;
% ramp_time = ramp_npts*dwell_time;
ramp_time = floor(ramp_time/0.002)*0.002; % Force ramp time to be a multiple of 2us
ramp_npts = ceil(ramp_time/dwell_time); % Recalculate number of points on ramp with rampt time forced to have multiple of 2us
ramp_time = ramp_npts*dwell_time;

pts_vec = [0:(npts-1)]';                                       % Sample point (time) vector

% %Calculate the max amplitude,G, needed to end up at a radius of 0.5 for
% %ideal case (gradient turn on immediately with no ramp)
% G = 1/(total_t);%G = 0.5/(grad_plateau_pts+ramp_npts);

plateau_start_pt = ramp_start_pt + ramp_npts;

% Calculate binary masks for each time region
in_ramp = (pts_vec>ramp_start_pt).*(pts_vec<plateau_start_pt); % Binary mask for times in ramp
in_plateau = (pts_vec>=plateau_start_pt);                    % Binary mask for times in plateau

grad_plateau_pts = npts - plateau_start_pt;    % Time in plateau
grad_plateau_pts = min(grad_plateau_pts, npts);

% Calculate times in each region
ramp_pts_vec = (pts_vec - ramp_start_pt).*in_ramp;                        % Time from start of ramp
plateau_pts_vec = (pts_vec - plateau_start_pt).*in_plateau;    % Time from start of plateau

%Calculate the amplitude of G over time
ramp_g = ramp_pts_vec/ramp_npts;  % "gradient" amplitude in ramp
plateau_g = in_plateau;      % "gradient" amplitude in plateau
gradient_dist = ramp_g + plateau_g;

% Calculate radial position from piecewise area calculations
ramp_dist = 0.5*ramp_pts_vec.*ramp_g;                                    % Trajectory distance in ramp
plateau_dist = plateau_pts_vec.*plateau_g + 0.5*ramp_npts*in_plateau;  % Trajectory distance in plateau
rad_dist = ramp_dist + plateau_dist;                                % Trajectory distance

rad_dist = rad_dist/npts;

ideal_dist = pts_vec;

% % Plotting - for debug purposes
% figure();
% hold on;
% plot(pts_vec,gradient_dist,'.r');
% plot(pts_vec,rad_dist,'.b');
% hold off;
% legend('Gradient','Radial Trajectory Distance');
% xlabel('Time (or sample number)');



