% This function enforces that the data is within +/- 0.5*Nyquist freq. If
% frequencies exceed Nyquist limits, the data will alias and the recon is
% too dumb to know.
%
% Note #1: This function assumes that the input data is in vector form [npts*nframes]
% Note #2: This function assumes that the input traj is in vector form [npts*nframes nDims]
%
% Usgae: [correctedData, correctedTraj, header] = enforceNyquistBounds(data, traj, header)
%
% Author: Scott Haile Robertson
% Date: 8/10/2014
%
function [correctedData, correctedTraj, header] = enforceNyquistBounds(data, traj, header)
% Calculate radial distance
radial_distance = sqrt(sum(traj.^2,2));

% Find indices to point that are outside Nyquist bounds
exceeds_nyquist = (radial_distance > 0.5);

nExceedingNyquist = sum(exceeds_nyquist);
correctedData = data;
correctedTraj = traj;
if(nExceedingNyquist > 0)
	% Warn user that we sampled post decay ramp
	h = warndlg(['Trajectory points exceed nyquist limit... ' ...
		'throwing away ' num2str(nExceedingNyquist) ...
		' samples to avoid aliasing. '...
		'Increase the matrix size to throw away less data.'],'!! Warning !!');
	uiwait(h);
	
	% Remove data and trajectory points that exceed Nyquist
	correctedData(exceeds_nyquist) = [];
	correctedTraj(exceeds_nyquist,:) = [];
end
end
