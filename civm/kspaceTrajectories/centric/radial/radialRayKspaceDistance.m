% radialRayKspaceDistance   Calculates normalized (0 to 0.5)radial kspace distance for a ray.
%   radialRayKspaceDistance(header) calculates the radial sampling
%   defined by the scan parmeters (receiver BW, t_off, pwrampa, pwramp, pwrampd, etc).
%   Returns the radial distances
%
%   Scale 0 to 0.5 (0.5 is Nyquist limit, anything greater is beyonw
%   Nyquist)
%
%   This code should exactly duplicate the trajectories calculated by
%   radish, allowing for a fair comparison of the two reconstructions. The
%   radish trajectories are calculated within:
%   /Volumes/recon_home/script/dir_radish/modules/source/proj3d_GHG/source/3dpr10_sg09.c
%   and are used with compiled code:
%   /Volumes/recon_home/script/dir_radish/modules/bin_macINTEL/grid3d01_do_all
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/07/19 $
function rad_dist = radialRayKspaceDistance(header)
% Pull relevant info from header
bw = header.rdb.rdb_hdr_user12;                 % Receiver bandwidth (kHz)
dwell_time = 1/(2*bw);                                             % Time between each sample
dwell_time = nearestMultipleOf(dwell_time,0.002); % Dwell time must be an integer multible of 2us
grad_delay_time = header.rdb.rdb_hdr_user22;    % Time between ADC on and start of gradient ramp
ramp_time = header.rdb.rdb_hdr_user1;           % Time to ramp gradients
decay_time = header.rdb.rdb_hdr_user38;
plat_time = header.rdb.rdb_hdr_user44;
nPts = header.rdb.rdb_hdr_frame_size;           % Number of sample points per frame/ray

% Put everything in pixel units rather than time
grad_delay_npts = grad_delay_time/dwell_time;
ramp_npts = ramp_time/dwell_time;
plat_npts = plat_time/dwell_time;
decay_npts = decay_time/dwell_time;

% Create sample vector
pts_vec = [0:(nPts-1)]';

% Calculate sample number of each region boundary
ramp_start_pt = grad_delay_npts; % Can handle negative gradient start times
plateau_start_pt = ramp_start_pt + ramp_npts;
decay_start_pt = plateau_start_pt + plat_npts;
decay_end_pt = decay_start_pt + decay_npts;

% Calculate binary masks for each time region
in_delay = pts_vec<ramp_start_pt;
in_ramp = (pts_vec>=ramp_start_pt).*(pts_vec<plateau_start_pt); % Binary mask for times in ramp
in_plateau = (pts_vec>=plateau_start_pt).*((pts_vec<decay_start_pt));                    % Binary mask for times in plateau
in_decay = (pts_vec>=decay_start_pt).*(pts_vec<decay_end_pt);

% Calculate times in each region
ramp_pts_vec = (pts_vec - ramp_start_pt).*in_ramp;                        % Time from start of ramp
plateau_pts_vec = (pts_vec - plateau_start_pt).*in_plateau;    % Time from start of plateau
decay_pts_vec = (pts_vec - decay_start_pt).*in_decay;    % Time from start of plateau

%Calculate the amplitude of G over time
ramp_g = ramp_pts_vec/ramp_npts;  % "gradient" amplitude in ramp
plateau_g = in_plateau;      % "gradient" amplitude in plateau
decay_g = (1-decay_pts_vec/decay_npts).*in_decay;
gradient_dist = ramp_g + plateau_g + decay_g;

% Calculate radial position from piecewise area calculations
ramp_dist = 0.5*ramp_pts_vec.*ramp_g;                                    % Trajectory distance in ramp
plateau_dist = plateau_pts_vec.*plateau_g + 0.5*ramp_npts*in_plateau;  % Trajectory distance in plateau
decay_dist = (0.5*ramp_npts + plat_npts).*in_decay + in_decay.*(decay_pts_vec*0.5.*(1+decay_g));

rad_dist = (ramp_dist + plateau_dist + decay_dist)/nPts;% Trajectory distance

ideal_dist = pts_vec;

% % Plotting - for debug purposes
% figure();
% hold on;
% plot(pts_vec,gradient_dist,'.r');
% plot(pts_vec,rad_dist,'.b');
% hold off;
% legend('Gradient','Radial Trajectory Distance');
% xlabel('Time (or sample number)');



