% This function reads a GE pfile and returns the header as well as the data
% in the scan file.
%
% Note #1: This function handles extended dynamic range
% Note #2: This function does not remove baseline views.
%
% Usgae: [header, data] = readPfile([pfile_name], [revision])
%
% Author: Scott Haile Robertson
% Date: 7/1/2013
%
function [header, data] = readPfile(pfile_name, revision)
%% Find a pfile if one is not given
if((nargin < 1) || isempty(pfile_name))
	[file, path] = uigetfile('*.*', 'Select Pfile');
	pfile_name = strcat(path, file);
end

%% Read the P-file Header
if((nargin < 2) || isempty(revision))
	% Try to figure out revision automatically
	header = readPfileHeader(pfile_name);
else
	header = readPfileHeader(pfile_name, revision);
end

% Pull relavant info from header
npts = header.rdb.rdb_hdr_frame_size;%view points
data_size_bytes = header.rdb.rdb_hdr_point_size;

% Check if extended dynamic range is used
switch(data_size_bytes)
	case 2
		precision = 'int16';
	case 4
		precision = 'int32';
	otherwise
		error('Only 2 and 4 are accepted as extended dynamic range options.');
end

% Read data from pfile
fid = fopen(pfile_name, 'r', 'ieee-le');
fseek(fid, header.rdb.rdb_hdr_off_data, 'bof');
data = fread(fid,inf,precision);
fclose(fid);

% Make data complex (real and imaginery parts alternate in pfile)
data = complex(data(1:2:end),data(2:2:end));

% Reshape into [pts x frames]
nframes  = length(data(:))/npts;
data = reshape(data,[npts nframes]);% Reshape into matrix [npts x nframes]

% Update header so its accurate to data
header.rdb.rdb_hdr_user20 = nframes;
end % function
