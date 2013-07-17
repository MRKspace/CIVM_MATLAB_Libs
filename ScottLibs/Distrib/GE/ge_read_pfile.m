% This function reads a GE pfile and returns the header as well as the data
% in the scan file. Note, this function does not remove baseline views. 
%
% Usgae: [header, data] = ge_read_pfile(pfile_name, [revision], [hdr_off], 
%                         [byte_order])
%
% Author: Scott Haile Robertson
% Date: 7/1/2013
%
function [header, data] = ge_read_pfile(pfile_name, revision, hdr_off, byte_order)

if(nargin == 0)
    [file, path] = uigetfile('*.*', 'Select Pfile');
    pfile_name = strcat(path, file);
end
if(nargin < 2)
    %Get revision info
    [revision, logo] = ge_read_basic_header(pfile_name);
end        
if(nargin < 3)
    %Typically there is no offset to the header
    hdr_off = 0;
    
    %Assume little endian format
    byte_order = 'ieee-le';
    
    % Can we read this from header? CSI extended mode uses int32
    precision='int16';
end

%% Read the P-file Header
header = ge_read_header(pfile_name, revision, hdr_off, byte_order);

% Read data from pfile
fid = fopen(pfile_name, 'r', byte_order);
fseek(fid, header.rdb.rdb_hdr_off_data, 'bof');
data = fread(fid,inf,precision);

% Data is complex (real and imaginery parts alternate)
data = complex(data(1:2:end),data(2:2:end));

% Reshape into [pts x frames]
npts = header.rdb.rdb_hdr_frame_size;%view points
nframes  = length(data(:))/npts;
data = reshape(data,npts,nframes);% Reshape into matrix
header.rdb.rdb_hdr_user20 = nframes; %Update header
end % function
