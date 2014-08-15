% This function removes remove baseline views from data, and returns an
% accurate header.
%
% Note #1: This function assumes that the data is in matrix form [npts x nframes]
%
% Usgae: [baselinelessData, header] = removeBaselineViews(rawData, header)
%
% Author: Scott Haile Robertson
% Date: 8/10/2014
%
function [baselinelessData, header] = removeBaselineViews(rawData, header)
	% Pull relavent info out of header
	baseline_skip_size = header.rdb.rdb_hdr_da_yres; 
	nframes = header.rdb.rdb_hdr_user20;
	npts = header.rdb.rdb_hdr_frame_size;
	
	% Remove baselines views
	baselinelessData = rawData;
	baselinelessData(:, 1:baseline_skip_size:nframes) = []; 

	% Update header to keep it in sync with data
	header.rdb.rdb_hdr_user20 = length(baselinelessData(:))/npts;
	header.rdb.rdb_hdr_da_yres = inf; % In case you try to remove baselines again, nothing will happen
end
