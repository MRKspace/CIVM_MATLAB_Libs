%PROCESSRADIALPFILE 
%   
function [data, traj, header] = processRadialPfile(pfile_name,revision_override,toff_override,autoSize, sizeScaling,verbose)

if(isempty(revision_override))
	[header, data] = readPfile(pfile_name);
else
	[header, data] = readPfile(pfile_name, revision_override);
end

if(verbose)
	% Display key header info
	dispPfileHeaderInfo(header);
end

% Override toff (optional)
header.rdb.rdb_hdr_user22 = toff_override;

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
[header, traj] = calculateNyquistMatrixSize(radialDistance, traj, ...
	header, autoSize, sizeScaling);
% 
% % Kill som frames
% kill_frames = [];
% nframes = header.rdb.rdb_hdr_user20;
% for i=6:20
% 	kill_frames = [kill_frames i:20:nframes];
% end
% 
% data(:,kill_frames) = [];
% traj(:,kill_frames,:) = [];
% header.rdb.rdb_hdr_user20 = size(data,2);

% Vectorize data and traj for recon
[data, traj] = vectorizeDataAndTraj(data, traj, header);

% Enforce Nyquist limits
[data, traj, header] = enforceNyquistBounds(data, traj, header);


end

