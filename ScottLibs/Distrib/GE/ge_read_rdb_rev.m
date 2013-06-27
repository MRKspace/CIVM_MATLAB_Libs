function [revision, logo] = ge_read_rdb_rev_and_logo(pfile_name,offset, byte_order)

if(nargin == 0)
	[file, path] = uigetfile('*.*', 'Select Pfile');
	pfile_name = strcat(path, file);
	offset = 0; %Assume no offset
	byte_order = 'ieee-le'; %Assume little endian
end

% Open the PFile
fid=fopen(pfile_name,'r',byte_order);         %Little-Endian format
if (fid == -1)
	error(sprintf('Could not open %s file.',pfile_name));
end

% start at correct offset
fseek(fid,offset,'bof');

% Get GE revision
revision = fread(fid,1,'float32',byte_order);
fseek(fid,16,'cof'); %skip a bit to GE logo
logo = char(fread(fid,10,'char',byte_order)); % rdbm  used to verify file 

% Close file
fclose(fid);