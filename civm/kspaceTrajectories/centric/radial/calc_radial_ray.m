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
function rad_dist = calc_radial_ray(dwell_time,	gradient_delay_time, ...
	delay_x_time,delay_y_time,delay_z_time,...
	ascending_ramp_time,plateau_time,descending_ramp_time,nSamplePoints)

% Pull relevant info from header
bw = header.rdb.rdb_hdr_user12;                 % Receiver bandwidth (kHz)
grad_delay_time = header.rdb.rdb_hdr_user22;    % Time between ADC on and start of gradient ramp
ramp_time = header.rdb.rdb_hdr_user1/1000;           % Time to ramp gradients
% ramp_time = header.rdb.rdb_hdr_user1;           % Time to ramp gradients
npts = header.rdb.rdb_hdr_frame_size;           % Number of sample points per frame/ray
dwell_time = 1/(2*bw);                                             % Time between each sample
dwell_time = nearestMultipleOf(dwell_time,0.002); % Dwell time must be an integer multible of 2us
total_t = npts * dwell_time;                                       % Total time per ray
% ramp_time = 0.512;
decay_time = 0.200;
decay_npts = 0.200/dwell_time;
plat_npts = 4;
plat_time = plat_npts * dwell_time;

% Put everything in sample units rather than time
grad_delay_pts = gradient_delay_time/dwell_time;
ascending_ramp_pts = ascending_ramp_time/dwell_time;
plateau_pts = plateau_time/dwell_time;
descending_ramp_pts = descending_ramp_time/dwell_time;

% Calculate the starting location of each region (handles negative values)
ascending_ramp_start_pt = grad_delay_pts;
plateau_start_pt = ascending_ramp_start_pt + ascending_ramp_pts;
descending_ramp_start_pt = plateau_start_pt + plateau_pts;

% Calculate binary masks for each time region
pts_vec = [0:(nSamplePoints-1)]';
gradient_delay_mask = pts_vec<ramp_start_pt;
ascending_ramp_mask = (pts_vec>=ramp_start_pt).*(pts_vec<plateau_start_pt); % Binary mask for times in ramp
plateau_mask = (pts_vec>=plateau_start_pt).*((pts_vec<decay_start_pt));                    % Binary mask for times in plateau
descending_ramp_mask = (pts_vec>=decay_start_pt).*(pts_vec<decay_end_pt);


if(nSamplePoints <=  ascending_ramp_start_pt)
	% We are only measuring while gradients are off (at DC)
	rad_dist = zeros(size(nSamplePoints));
elseif((nSamplePoints > ascending_ramp_start_pt) & (nSamplePoints <= plateau_start_pt))
	% We are only measuring during the ascending ramp
	0.5*(nSamplePoints - ascending_ramp_start_pt)/nSamplePoints
elseif((nSamplePoints > plateau_start_pt) & (nSamplePoints <= descending_ramp_start_pt))
		% We are measuring during the ascending ramp and plateau
	
elseif((nSamplePoints > ascending_ramp_start_pt) & (nSamplePoints <= plateau_start_pt))
elseif(nSamplePoints > descending_ramp_start_pt)

end
rad_dist = zeros(size(nSamplePoints));




