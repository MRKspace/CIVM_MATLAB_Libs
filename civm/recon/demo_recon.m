% This demo shows how to batch reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% % % Start with a clean slate
clc; clear all; close all; fclose all;

% Required parameters
model_type = 'grid'; % nufft or grid
recon_type = 'lsq';   % lsq (Least Squares) or cg (Conjugate Gradient)
dcf_type = 'pipe'; % iter (Pipe itterative), voronoi (Voronoi), hitplane (hitplant), analytical (analytical)
proximity_metric = 'L2'; % L2 (L2-norm) or L1 (L1-norm)
kernel_type = 'kaiser-bessel'; % kaiser-bessel
overgridfactor = 2;
nNeighbors = 3;
kaiser_b_override = [];
sigma = 0.506;
nIter = 25; % 25 is overkill, but the recommended default
saveIter = 1:nIter; % only for CG recon

% % Optional Parameters
% ascending_ramp_time_override  = 0.260; % pw_gxwa
% descending_ramp_time_override = 0.200;  % pw_gxwd/1000
% plateau_time_override         = 10000; % pw_gxw/1000
% matrixSize_override = 128*[1 1 1 ];
% toff_override = 0.068;
% primeplus_override = 101;

% For Ventilation:
ascending_ramp_time_override  = 0.992; % pw_gxwa
descending_ramp_time_override = 0.2;  % pw_gxwd/1000
plateau_time_override         = 2.976; % pw_gxw/1000
matrixSize_override = 150*[1 1 1];
toff_override = 0.006;
primeplus_override = 137.508;

fft_size = 4*matrixSize_override;

%Optional parameters
revision_override = [];  %Optional override if it can't be automatically read from the pfile
nyquistScaling = 1*[1 1 1];
verbose = 1;

pfile_name = filepath('/home/scott/Public/data/20140827/CANCER_BEM_082714/129Xe_vent/P43008.7')
% pfile_name = filepath('/home/scott/Public/data/20140725/jerry/P03584.7')

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
header.rdb.rdb_hdr_user23 = primeplus_override;
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

% Vectorize data and traj for reconvoronoi
[data, traj] = vectorizeDataAndTraj(data, traj, header);

% Enforce Nyquist limits
[data, traj, header] = enforceNyquistBounds(data, traj, header);

%% Reconstruction
% Create System Model - only recalculate the model if necessary
if(~exist('model','var'))
	% Note, creating this object can be computationally intensive
	switch(lower(model_type))
		case 'nufft'
			model = NufftSystemModel(traj, header.MatrixSize, ...
				overgridfactor, [nNeighbors nNeighbors nNeighbors]);
		case 'grid'
			% Create kernel object
			switch(kernel_type)
				case 'kaiser-bessel'
					kernelObj = KaiserBesselGriddingKernel(nNeighbors, ...
						overgridfactor, kaiser_b_override, verbose);
				case 'gaussian'
				case 'kaiser-bessel'
					kernelObj = GaussianGriddingKernel(nNeighbors, ...
						overgridfactor, sigma, verbose);
				otherwise
					error('Kernel not supported.');
			end
			
			% Create Proximity metric
			switch(proximity_metric)
				case 'L2'
					proxObj = L2GriddingProximity(kernelObj, verbose);
				case 'L1'
					proxObj = L1GriddingProximity(kernelObj, verbose);
				otherwise
					error('Proximity metric not supported.');
			end
			clear kernelObj;
			
			model = GriddingSystemModel(traj, header.MatrixSize, ...
				overgridfactor, nNeighbors, proxObj);
		otherwise
			error('System model not supported.');
	end
end

% Create Reconstruction Object - only recalculate the model if necessary
if(~exist('reconObj','var'))
	% Note, creating this object can be computationally intensives
	switch(lower(recon_type))
		case 'lsq'
			reconObj = LsqRecon(model, verbose);
			
			% Create Density compensation object
			switch(dcf_type)
				case 'iter'
					dcfObj = IterativeDcf(model, nIter, verbose);
				case 'voronoi'
					dcfObj = VoronoiDcf(traj, verbose);
				case 'hitplane'
					dcfObj = HitplaneDcf(model, verbose);
				case 'analytical'
					dcfObj = AnalyticalDcf(traj, verbose);
				otherwise
					error('dcf_type not implemented');
			end
			
			switch(dcfObj.dcf_style)
				case 'gridspace'
					radial_dcf = (model.A*dcfObj.dcf);
				case 'dataspace'
					radial_dcf = dcfObj.dcf;
				otherwise
					error('DCF style not recognized');
			end
			
			nPts = header.rdb.rdb_hdr_frame_size;
			nFrames = header.rdb.rdb_hdr_user20;
			radial_dcf = reshape(radial_dcf,[nPts nFrames]);
			radial_dcf = mean(radial_dcf,2);
			
		case 'cg'
			if(~isempty(dcf_type))
				warning('DCF is not necessary for CG method');
			end
			reconObj = ConjGradRecon(model, nIter, saveIter, verbose);
		otherwise
			error('Reconstruction type not supported.');
	end
end

details = [model_type '_dcf' dcfObj.dcf_unique_name '-' proxObj.kernelObj.unique_string '_prox' proxObj.unique_string ]

save(['radialDCF_' details '.mat'],'radial_dcf');

% Reconstruct kspace data - Note output is kspace domain
reconVol = reconObj.reconstruct(data, dcfObj);

% Put data back into image space (undoes overgridding, shifts, etc)
reconVol = model.imageSpace(reconVol);
nii = make_nii(abs(reconVol),header.rdb.rdb_hdr_fov./header.MatrixSize, 0.*header.MatrixSize, [16], 'test');
save_nii(nii,['recon_' details '.nii'],16);

% Show image
imslice(abs(reconVol));