% This function reads a GE pfile and returns the software revision 
% of the scan file.  
%
% Usgae: [revision] = readSoftwareRev([pfile_name])
%
% Author: Scott Haile Robertson
% Date: 7/1/2013
%
function [revision] = readSoftwareRev(pfile_name)
if(nargin < 1)
    [file, path] = uigetfile('*.*', 'Select Pfile');
    pfile_name = strcat(path, file);
end

% Open the PFile
fid=fopen(pfile_name,'r','ieee-le');         %Little-Endian format
if (fid == -1)
	error(sprintf('Could not open %s file.',pfile_name));
end

% start at correct offset
fseek(fid,0,'bof');

% Get GE revision
revision = floor(fread(fid,1,'float32','ieee-le'));

% Close file
fclose(fid);