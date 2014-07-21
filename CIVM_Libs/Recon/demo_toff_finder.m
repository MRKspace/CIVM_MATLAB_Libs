% This demo shows how to reconstruct a GE Pfile using Fessler's NUFFT
% algorithm.

% Start with a clean slate
clc; clear all; close all; fclose all;

% Define reconstruction options
if(exist('~/.matlab_recon_prefs.mat'))
	load('~/.matlab_recon_prefs.mat');
end

pfile_root_dir = '/home/scott/Public/pfiles/20140619/';

% % % Get pfile
if(exist('pfile_root_dir','var'))
	headerfilename = filepath(pfile_root_dir)
else
	headerfilename = filepath()
end
% headerfilename = filepath('/home/scott/Public/pfiles/20140525/imagingtests/P20480.7')

% headerfilename = filepath('/home/scott/Desktop/test/');
datafilename = '';
overgridfactor = 2;
nNeighbors = 3;
scale = 1*[1 1 1]% Scales the matrix dimmensions
dcf_iter = 25;
useAllPts = 1;

toff_start = 0.070;
toff_incr = 0.001;
toff_end = 0.1;

for toff = toff_start:toff_incr:toff_end
	toff
	save('toff.mat','toff');
	% Read in the file and prepare for generic reconstruction
	[revision, logo] = ge_read_rdb_rev_and_logo(headerfilename);
	[data, traj, weights, header] = GE_Recon_Prep(headerfilename, ...
		floor(revision), datafilename);
	
	inv_scale = 1./scale;
	N = header.MatrixSize;
	for i=1:length(N)
		N(i) = max(floor(N(i)*scale(i)),1);
	end
	if(useAllPts)
		traj = (40/48)*0.5*traj;
		N = 2*N;
	end
	for i=1:length(N)
		traj(:,i) = traj(:,i)*inv_scale(i);
	end
	J = [nNeighbors nNeighbors nNeighbors];
	K = ceil(N*overgridfactor);
	
	%% Throw away data outside the BW
	throw_away = find((traj(:,1)>0.5) + (traj(:,2)>0.5) + (traj(:,3)>0.5) + ...
		(traj(:,1)<-0.5) + (traj(:,2)<-0.5) + (traj(:,3)<-0.5));
	traj(throw_away(:),:)=[];
	data(throw_away(:))=[];
% 	weights(throw_away(:))=[];
	
	% Create reconstruction object
	reconObj = ConjugatePhaseReconstructionObject(traj, N, J, K, dcf_iter);
	
	% Reconstruct data
	recon_vol = reconObj.reconstruct(data);
	
	% % Save volume
	base = ['toff_' num2str(toff)];
	nii = make_nii(abs(recon_vol));
	save_nii(nii, [base '.nii'], 16);
end

tidx = 1;
ntoff = length([toff_start:toff_incr:toff_end]);
for toff = toff_start:toff_incr:toff_end
	base = ['toff_' num2str(toff)];
	nii = load_nii([base '.nii']);
	if(toff == toff_start)
		recon_vol = zeros([size(nii.img) ntoff]);
	end
	recon_vol(:,:,:,tidx)=nii.img;
	tidx = tidx + 1;
end

figure();
imslice(abs(recon_vol));
