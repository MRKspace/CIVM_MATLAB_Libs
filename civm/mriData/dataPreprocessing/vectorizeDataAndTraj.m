function [vectorizedData, vectorizedTraj] = vectorizeDataAndTraj(data, traj, header)
	% Pull relavant info from header
	nDims = 3;
	nPts = header.rdb.rdb_hdr_frame_size;
	nFrames = header.rdb.rdb_hdr_user20;
	
	% Vectorize data
	vectorizedData = reshape(data,[nPts*nFrames 1]);
	vectorizedTraj = reshape(traj,[nPts*nFrames nDims]);
end