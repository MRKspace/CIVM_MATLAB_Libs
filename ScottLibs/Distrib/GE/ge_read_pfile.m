function [header, fid_data] = ge_read_pfile(pfile_name, hdr_off, byte_order, undo_loopfactor)

if(nargin == 0)
    [file, path] = uigetfile('*.*', 'Select Pfile');
    pfile_name = strcat(path, file);
    
    %Typically there is no offset to the header
    hdr_off = 0;
    
    %Assume little endian format
    byte_order = 'ieee-le';
    
    % Default is to undo loopfactor
    undo_loopfactor = 1;
end

%% Read the P-file Header
header = ge_read_header(pfile_name, hdr_off, byte_order);

precision='int16';          % Can we read this from header? CSI extended mode uses int32

% fid_data = FID_Data();
fid_data = FID_Data(pfile_name, byte_order, precision, header);
if(undo_loopfactor)
    fid_data = fid_data.undo_loopfactor();
end
