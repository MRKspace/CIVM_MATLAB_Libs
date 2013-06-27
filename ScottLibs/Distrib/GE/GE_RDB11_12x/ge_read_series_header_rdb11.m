function strct = ge_read_series_header(pfile_name,offset, byte_order)

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

strct = struct('base_p_file',pfile_name);
fclose(fid);
