% This function calculates the matrix size that just meets the Nyquist
% limit of the given radial trajectory. It can also (optionally) set the
% reconstructed Matrix size to some relative ammount of Nyquist size. If
% verbosity is on, it announces the Nyquist size.
%
% Usage: header = calculateNyquistMatrixSize(radialTraj, header, [setSize], [relativeSize])
%
% Author: Scott Haile Robertson
% Date: 8/10/2014
%
function [header, adjustedTraj] = calculateNyquistMatrixSize(...
	radialDistance, traj, header, relativeSize)
	% Use default optional parameters if they are not provided
	if(nargin < 4 | isempty(relativeSize))
		% Use Nyquist limit by default
		relativeSize = ones(1,3);
	end
	
	% Use the original npts, not after any data processing because this is
	% how the gradient amplitudes are scaled
	npts_orig = header.rdb.rdb_hdr_user7;
	nyquistMatrixSize = 2*npts_orig*max(radialDistance(:));
	
	disp(['Matrix Size for Nyquist limit = ' num2str(floor(nyquistMatrixSize))]);
	
	if(isempty(header.MatrixSize))
		header.MatrixSize = ceil(relativeSize.*(nyquistMatrixSize*ones(1,3))); % Really this should be a floor operation, but ceil makes sure we dont throw away too much data
		disp(['Setting Matrix size to = ' num2str(header.MatrixSize)]);
	end
	
	% Adjust trajectories for Matrix size
	orig_matrix_size = (npts_orig*ones(1,3));
	inverse_scale = orig_matrix_size./header.MatrixSize; % Trick to avoid division
	nDim = size(traj,3);
	adjustedTraj = zeros(size(traj));
	for iDim=1:nDim
		adjustedTraj(:,:,iDim) = traj(:,:,iDim)*inverse_scale(iDim);
	end
end