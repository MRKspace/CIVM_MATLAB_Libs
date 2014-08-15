% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% Start with a clean slate
% clc; clear all; close all; fclose all;

%% Setup parameters
% Get pfile
pfile_name = filepath('/home/scott/Desktop/')

% Required parameters
model_type = 'nufft'; % nufft or grid
recon_type = 'lsq';   % lsq (Least Squares) or cg (Conjugate Gradient)
overgridfactor = 2;
nNeighbors = 3;
nIter = 25; % 25 is overkill, but the recommended default

% % Rohan parameters :)
% % For Dissolved:
% ascending_ramp_time_override  = 0.252; % pw_gxwa
% descending_ramp_time_override = 0.2;  % pw_gxwd/1000
% plateau_time_override         = 0.764; % pw_gxw/1000
% matrixSize_override = [128 128 128];
% toff_override = 0.006;
% primeplus_override = 137.508;

% % For Ventilation:
% ascending_ramp_time_override  = 0.992; % pw_gxwa
% descending_ramp_time_override = 0.2;  % pw_gxwd/1000
% plateau_time_override         = 2.976; % pw_gxw/1000
% matrixSize_override = [128 128 128];
% toff_override = 0.006;
% primeplus_override = 137.508;

% For Proton:
ascending_ramp_time_override  = 0.512; % pw_gxwa
descending_ramp_time_override = 0.2;  % pw_gxwd/1000
plateau_time_override         = 1.536; % pw_gxw/1000
matrixSize_override = [256 256 256];
toff_override = 0.0402;
primeplus_override = 137.508;


%Optional parameters
revision_override = [];  %Optional override if it can't be automatically read from the pfile
nyquistScaling = 1*[1 1 1];
verbose = 1;

%% Read and Process Pfile
if(isempty(revision_override))
	[header, data] = readPfile(pfile_name);
else
	[header, data] = readPfile(pfile_name, revision_override);
end

if(verbose)
	% Display key header info
	dispPfileHeaderInfo(header);
end

% Override header values (optional)
header.rdb.rdb_hdr_user22 = toff_override;
header.rdb.rdb_hdr_user1 = ascending_ramp_time_override; % ascending gradient ramp time
header.rdb.rdb_hdr_user38 = descending_ramp_time_override;  % descending gradient ramp time
header.rdb.rdb_hdr_user44 = plateau_time_override;% gradient plateau time

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
if(~exist('model','var') | ~model.isCompatible(traj,header,overgridfactor,nNeighbors))
	% Note, creating this object can be computationally intensive
	switch(lower(model_type))
		case 'nufft'
			model = NufftSystemModel(traj, header.MatrixSize, ...
				overgridfactor, [nNeighbors nNeighbors nNeighbors]);
		case grid
			model = GriddingSystemModel(traj, header.MatrixSize, ...
				overgridfactor, nNeighbors);
		otherwise
			error('System model not supported.');
	end
end

% Create Reconstruction Object - only recalculate the model if necessary
% if(~exist('reconObj','var') | reconObj.isCompatible(model,dcf_iter,recon_type))
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
% end

% Reconstruct kspace data - Note output is kspace domain
reconVol = reconObj.reconstruct(data);

% Put data back into image space (undoes overgridding, shifts, etc)
reconVol = model.imageSpace(reconVol);

%% Display reconstruction
figure();
imslice(abs(reconVol),'Reconstruction');
