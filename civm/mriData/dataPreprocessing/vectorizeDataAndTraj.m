function [data, traj, weights] = vectorizeDataAndTraj(data, traj, weights, header)
	% Pull relavant info from header
	nDims = 3;
	nPts = header.rdb.rdb_hdr_frame_size;
	nFrames = header.rdb.rdb_hdr_user20;
	
	% Vectorize data
	data = reshape(data,[nPts*nFrames 1]);
	weights = reshape(weights,[nPts*nFrames 1]);
	traj = reshape(traj,[nPts*nFrames nDims]);
end