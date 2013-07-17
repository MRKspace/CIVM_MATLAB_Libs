function [revision, logo] = ge_read_basic_header(pfile_name,hdr_off, byte_order)

if(nargin < 1)
    [file, path] = uigetfile('*.*', 'Select Pfile');
    pfile_name = strcat(path, file);
end
if(nargin < 3)
    %Typically there is no offset to the header
    hdr_off = 0;
    
    %Assume little endian format
    byte_order = 'ieee-le';
end

% Open the PFile
fid=fopen(pfile_name,'r',byte_order);         %Little-Endian format
if (fid == -1)
	error(sprintf('Could not open %s file.',pfile_name));
end

% start at correct offset
fseek(fid,hdr_off,'bof');

% Get GE revision
revision = fread(fid,1,'float32',byte_order);
fseek(fid,30,'cof'); %skip a bit to GE logo
logo = char(fread(fid,10,'char',byte_order))'; % rdbm  used to verify file 

% Close file
fclose(fid);