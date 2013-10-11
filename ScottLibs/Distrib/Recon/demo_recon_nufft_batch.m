% This is a demo of how to use a RecursiveFileAction to reconstruct a set
% of Pfiles using the NUFFT algorithm. The demo takes advantage of creating
% a reconObj which precalculates the DCF. The precalculation will save a
% good deal or time in reconstructing multiple files.
%
% Author: Scott Haile Robertson
% Date: 6/28/2013
%
% Start with a clean slate
clc; clear all; close all;

% Define reconstruction options
datafilename = '';
overgridfactor = 2;
nNeighbors = 3;
scale = 1;
dcf_iter = 25;
useAllPts = 1;
   
% Get a list of all the files to be reconstructed
files_to_recon = demo_findRadialPFiles();

% Read first pfile for trajectories and header
headerfilename = filepath(files_to_recon{1});
[revision, logo] = ge_read_rdb_rev_and_logo(headerfilename);
[data, traj, weights, header] = GE_Recon_Prep(headerfilename, ...
    floor(revision), datafilename);

inv_scale = 1/scale;
N = floor(scale*header.MatrixSize);
if(useAllPts)
    traj = 0.5*traj;
    N = 2*N;
end
traj = traj*inv_scale;
J = [nNeighbors nNeighbors nNeighbors];
K = ceil(N*overgridfactor);

%% Throw away data outside the BW
throw_away = find((traj(:,1)>0.5) + (traj(:,2)>0.5) + (traj(:,3)>0.5) + ...
    (traj(:,1)<-0.5) + (traj(:,2)<-0.5) + (traj(:,3)<-0.5));
traj(throw_away(:),:)=[];
data(throw_away(:))=[];
weights(throw_away(:))=[];

% Create reconstruction object
reconObj = ConjugatePhaseReconstructionObject(traj, N, J, K, dcf_iter);

% Now run the recon on all batched files - this is much faster than running
% the recon separately on each pfile because we don't have to create the 
% reconstruction object and calculate density compensation each time. 
% If you are reconstructing multiple similar reconstructions,
% its much more efficient to create the reconObj, then perform all similar
% reconstructions using that object.
numFilesToRecon = length(files_to_recon);
for i=1:numFilesToRecon
    % get next file ready
    headerfilename = filepath(files_to_recon{i});
    
    % Read data from next file
    [data, traj, weights, header] = GE_Recon_Prep(headerfilename, ...
        floor(revision), datafilename);

    % Reconstruct next file
    recon_vol = reconObj.reconstruct(data);
    disp(['Reconstructed file ' num2str(i) '.']);
    
    % Save the reconstruction of the file
    nii = make_nii(abs(recon_vol), [1 1 1], [1 1 1], 32);
    save_nii(nii,[files_to_recon{1} '_recon.nii'],16);
end

