% This demo shows how to batch reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% % Start with a clean slate
clc; clear all; close all; fclose all;

% Required parameters
model_type = 'grid'; % nufft or grid
recon_type = 'lsq';   % lsq (Least Squares) or cg (Conjugate Gradient)
overgridfactor = 6;
nNeighbors = 6;
nIter = 25; % 25 is overkill, but the recommended default

% Optional Parameters
ascending_ramp_time_override  = 0.508; % pw_gxwa
descending_ramp_time_override = 20000;  % pw_gxwd/1000
plateau_time_override         = 10000; % pw_gxw/1000
matrixSize_override = 128*[1 1 1 ];
toff_override = 0.132;
primeplus_override = 101;

%Optional parameters
revision_override = [];  %Optional override if it can't be automatically read from the pfile
nyquistScaling = 1*[1 1 1];
verbose = 1;

pfile_name = filepath('/home/scott/Public/pfiles/demo/P16384.7_lung')

%% Read and Process Pfile
if(isempty(revision_override))
	[header, data] = readPfile(pfile_name);
else
	[header, data] = readPfile(pfile_name, revision_override);
end

% Override header values (optional)
header.rdb.rdb_hdr_user22 = toff_override;
header.rdb.rdb_hdr_user1 = ascending_ramp_time_override; % ascending gradient ramp time
header.rdb.rdb_hdr_user38 = descending_ramp_time_override;  % descending gradient ramp time
header.rdb.rdb_hdr_user44 = plateau_time_override;% gradient plateau time
% header.rdb.rdb_hdr_user23 = primeplus_override;
if(verbose)
	% Display key header info
	dispPfileHeaderInfo(header);
end

% Remove baselines
[data, header] = removeBaselineViews(data, header);

% Calculate trajectory for a single radial ray
radialDistance = radialRayKspaceDistance(header);

% Only keep data during readout
[radialDistance, data, header] = removeNonReadoutSamples(radialDistance, data, header);

% Distribute rays onto 3d sphere
traj = calculate3dTrajectories(radialDistance, header);

% Undo loopfactor
[data, traj, header] = undoloopfactor(data, traj, header);

% Calculate Maximum volume size for Nyquist
header.MatrixSize = matrixSize_override;
[header, traj] = calculateNyquistMatrixSize(radialDistance, traj, ...
	header, nyquistScaling);

% Vectorize data and traj for recon
[data, traj] = vectorizeDataAndTraj(data, traj, header);

% Enforce Nyquist limits
[data, traj, header] = enforceNyquistBounds(data, traj, header);

%% Reconstruction
% Create System Model - only recalculate the model if necessary
% if(~exist('model','var'))
	% Note, creating this object can be computationally intensive
	switch(lower(model_type))
		case 'nufft'
			model = NufftSystemModel(traj, header.MatrixSize, ...
				overgridfactor, [nNeighbors nNeighbors nNeighbors]);
		case 'grid'
% 			traj = traj(1:300,:);
			
			model = GriddingSystemModel(traj, header.MatrixSize, ...
				overgridfactor, nNeighbors);
		otherwise
			error('System model not supported.');
	end
% end

% Create Reconstruction Object - only recalculate the model if necessary
if(~exist('reconObj','var'))
	% Note, creating this object can be computationally intensive
	switch(lower(recon_type))
		case 'lsq'
			reconObj = LsqRecon(model, nIter, verbose);
		case 'cg'
			saveIter = 1:nIter;
			reconObj = ConjGradRecon(model, nIter, saveIter, verbose);
		otherwise
			error('Reconstruction type not supported.');
	end
end

% Reconstruct kspace data - Note output is kspace domain
reconVol = reconObj.reconstruct(data);

% Put data back into image space (undoes overgridding, shifts, etc)
reconVol = model.imageSpace(reconVol);

% % Save data
% recon_filename = [starting_dir filesep() 'recon_' pfile_name '.nii'];
recon_filename = ['recon_overgrid' num2str(overgridfactor) '_nNeigh' num2str(nNeighbors)  '.nii'];
nii = make_nii(abs(reconVol));
save_nii(nii,recon_filename,16);

% Show image
imslice(abs(reconVol));