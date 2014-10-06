% This demo shows how to batch reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% % % Start with a clean slate
clc; clear all; close all; fclose all;

% Required parameters
verbose = 1;
model_type = 'grid'; % nufft or grid or exact
recon_type = 'lsq';   % lsq (Least Squares) or cg (Conjugate Gradient)
dcf_type = 'iter'; % iter (Pipe itterative), voronoi (Voronoi), hitplane (hitplant), analytical (analytical), none
proximity_metric = 'L2'; % L2 (L2-norm) or L1 (L1-norm)
kernel_type = 'optimal'; % kaiser-bessel, sinc, gaussian, or optimal
overgridfactor = 2;
nNeighbors = 3/overgridfactor;   % In recon image size units
kaiser_b_override = [20];
sigma = 0.5;
kludge = 3;
saveEveryIter = 1;
nIter = 7; % 25 is overkill, but the recommended default
saveIter = unique([[1:100:nIter] nIter]); % only for CG recon
% saveIter = unique([nIter]); % only for CG recon
amplify_snr = 0; % Amplify signal to account for decay?
snr_recon_weights = 0; % Power of SNR weights (0=unity, 1=lin, 2=squared)
weight_type = 0; %; 0=equal, 1=frameSNR 2=sampleSNR
extra_string = ['ampSnr' num2str(amplify_snr) '_srnReconWeightPow' num2str(snr_recon_weights) ...
	'_weightType' num2str(weight_type)];

% % % Human Ventilation Parameters
% ascending_ramp_time_override  = 0.508; % pw_gxwa
% descending_ramp_time_override = 0.200;  % pw_gxwd/1000
% plateau_time_override         = 1.28; % pw_gxw/1000
% matrixSize_override = 128*[1 1 1 ];
% toff_override = 0.1296;
% primeplus_override = 101;

% % % Rohan parameters :)
% % For Dissolved:
% ascending_ramp_time_override  = 0.252; % pw_gxwa
% descending_ramp_time_override = 0.2;  % pw_gxwd/1000
% plateau_time_override         = 0.764; % pw_gxw/1000
% matrixSize_override = [128 128 128];
% toff_override = 0.006+2*0.062;
% primeplus_override = 137.50776405003784;
% % primeplus_override = 137.508;

% % For "high res" Ventilation:
% ascending_ramp_time_override  = 0.992; % pw_gxwa
% descending_ramp_time_override = 0.2;  % pw_gxwd/1000
% plateau_time_override         = 14.68; % pw_gxw/1000
% matrixSize_override = 160*[1 1 1];
% % toff_override = 0.006+2*0.062;
% toff_override = 0.1515;
% % primeplus_override = 137.508;
% primeplus_override = 137.50776405003784;

% For Ventilation:
ascending_ramp_time_override  = 0.992; % pw_gxwa
descending_ramp_time_override = 0.2;  % pw_gxwd/1000
plateau_time_override         = 2.976; % pw_gxw/1000
matrixSize_override = 128*[1 1 1];
toff_override = 0.006;
primeplus_override = 137.508;

% % For Proton:
% ascending_ramp_time_override  = 0.512; % pw_gxwa
% descending_ramp_time_override = 0.2;  % pw_gxwd/1000
% plateau_time_override         = 1.536; % pw_gxw/1000
% matrixSize_override = 256*[1 1 1];
% toff_override = 0.04;
% primeplus_override = 101;

%Optional parameters
revision_override = [];  %Optional override if it can't be automatically read from the pfile
nyquistScaling = 1*[1 1 1];
% pfile_name = filelsqpath('/home/scott/Downloads/P12800.7');
% pfile_na me = filepath('/home/scott/Public/data/')
% pfile_name = filepath('/home/scott/Public/data/20140910/CONTROL_CREP_091014/129Xe_vent_scott/P42496.7');
% pfile_name = filepath('/home/scott/Public/pfiles/demo/P16384.7_lung');
pfile_name = filepath('/home/scott/Documents/Presentations/Seminar_20140904/LES_082014/129Xe_vent/P46080.7')
% pfile_name = filepath('/home/scott/Desktop/P04096.7');
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
header.rdb.rdb_hdr_user44 = plateau_time_override;% gradient plateau timesinc
header.rdb.rdb_hdr_user23 = primeplus_override;
if(verbose)
	% Display key header info
	dispPfileHeaderInfo(header);
end

% Remove baselines
[data, header] = removeBaselineViews(data, header);

% Calculate trajectory for a single radial ray
radialDistance = radialRayKspaceDistance(header);

% % Throw away data if requested
% data = data(1:recon_nPts,:);
% radialDistance = radialDistance(1:recon_nPts);
% header.rdb.rdb_hdr_frame_size = size(data,1);

% Compensate for Decay via amplification
lastDCpt = find(radialDistance==0,1,'last');
dc_pts = lastDCpt;
max_DC = max(abs(data(dc_pts,:)));
frame_weights = abs(mean(data(dc_pts,:),1));
frame_weights = repmat(frame_weights,[header.rdb.rdb_hdr_frame_size 1]);
if(amplify_snr==1)
	data= max_DC*data./frame_weights;
end

if(weight_type == 0)
	weights = ones(size(frame_weights));
elseif(weight_type == 1)
	weights = frame_weights;
else
	weights = abs(data/sum(abs(data(:)))); % Should sum to 1 so we dont cause issues in CG
	weigh ts = weights.^snr_recon_weights;
end

% Only keep data during gradients on
[radialDistance, data, weights, header] = removeNonReadoutSamples(radialDistance, data, weights, header);

% Distribute rays onto 3d sphere
traj = calculate3dTrajectories(radialDistance, header);

% Undo loopfactor
[data, traj, header] = undoloopfactor(data, traj, header);

% header.rdb.rdb_hdr_frame_size = keepNpts;
% data = data(1:keepNpts,:);
% traj = traj(1:keepNpts,:,:);

% Calculate Maximum volume size for Nyquist
header.MatrixSize = matrixSize_override;
[header, traj] = calculateNyquistMatrixSize(radialDistance, traj, ...
	header, nyquistScaling);

% bframe = 1;
% nvptrig = 5;
% data = data(:,bframe:nvptrig:end);
% weights = weights(:,bframe:nvptrig:end);
% traj = traj(:,bframe:nvptrig:end,:);
% header.rdb.rdb_hdr_user20 = size(data,2);

% Vectorize data and traj for recon
[data, traj, weights] = vectorizeDataAndTraj(data, traj, weights, header);

% Enforce Nyquist limits
[data, traj, weights, header] = enforceNyquistBounds(data, traj, weights, header);

%% Reconstruction
% Create System Model - only recalculate the model if necessary
if(~exist('model','var'))
	% Note, creating this object can be computationally intensive
	switch(lower(model_type))
		case 'exact'
			model = ExactSystemModel( traj,header.MatrixSize);
		case 'nufft'
			model = NufftSystemModel(traj, header.MatrixSize, ...
				overgridfactor, [nNeighbors nNeighbors nNeighbors]);
		case 'grid'
			% Create kernel object
			switch(kernel_type)
				case 'kaiser-bessel'
					kernelObj = KaiserBesselGriddingKernel(nNeighbors, ...
						overgridfactor, kludge, kaiser_b_override, verbose);
				case 'gaussian'
					kernelObj = GaussianGriddingKernel(nNeighbors, ...
						overgridfactor, sigma, verbose);
				case 'sinc'
					kernelObj = SincGriddingKernel(nNeighbors, ...
						overgridfactor, verbose);
				case 'optimal'
					kernelObj = OptimalGriddingKernel(nNeighbors, header.MatrixSize(1), ...
						overgridfactor, 1000000, 100, verbose);
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
			
			model = GriddingSystemModel(traj, weights, header.MatrixSize, ...
				overgridfactor, nNeighbors, proxObj, verbose);% % Show image
			% imslice(abs(reconVol));
		otherwise
			error('System model not supported.');
	end
end

% Create Reconstruction Object - only recalculate the model if necessary
if(~exist('reconObj','var'))
	% Note, creating this object can be computationally intensives
	switch(lower(recon_type))
		case 'lsq'
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
				case 'none'
					dcfObj = UnityDcf(traj,verbose);
				otherwise
					error('dcf_type not implemented');
			end
			
			reconObj = LsqRecon(model, dcfObj, verbose);
			clear model;
		case 'cg'
			reconObj = ConjGradRecon(model, dcfObj, nIter, saveIter, verbose);
			clear model;
		otherwise
			error('Reconstruction type not supported.');
	end
end

% Needs details from prox obj, model, dcfObj, kern, recon
if(isempty(extra_string))
	details = reconObj.unique_string;
else
	details = [reconObj.unique_string '_' extra_string];
end
% details = [details '_nPtsCutoff' num2str(recon_nPts)];
details = ['toff' num2str(toff_override) '_' details];
disp(['Reconstructing ' details '...']);

% Reconstruct kspace data - Note output is kspace domain
switch(lower(recon_type))
	case 'lsq'
		reconObj = reconObj.reconstruct(data, weights);
	case 'cg'
		startingGuess = zeros(reconObj.model.reconMatrixSize);
		reconObj = reconObj.reconstruct(data, weights,startingGuess(:), @save_function,details);
	otherwise
		error('Reconstruction type not supported.');
end

nii = make_nii(abs(reconObj.model.reconVol),header.rdb.rdb_hdr_fov./header.MatrixSize, 0.*header.MatrixSize, [16], 'test');
save_nii(nii,['recon_' details '.nii'],16);
clear nii;


% Show image
figure()
imslice(abs(reconObj.model.reconVol),['IMAGE' details]);

% figure()
% imslice(fftshift(abs(reconVol_kspace)),['LOG KSPACE' details]);
