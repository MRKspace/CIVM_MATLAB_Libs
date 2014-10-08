% This function will read a PFiles header information according to the GE 
% format defined by the RDBM revision of the file. Using this function
% requires that the proper parsing files have been generated (use  to 
% generate files for a specific RBDM revision). 

% Note, RBDM revision is not the same as GE revision.
%
% Usage: header = readPfileHeader([pfile_name], [revision])
%
% Author: Scott Haile Robertson
% Date:   7/1/2013
%
function header = readPfileHeader(pfile_name, revision)
if(nargin < 1)
    [file, path] = uigetfile('*.*', 'Select Pfile');
    pfile_name = strcat(path, file);
end
if(nargin < 2)
    revision = readSoftwareRev(pfile_name);
end

% Add the main header
main_header_cmd = ['header = struct(''rdb'', ge_read_rdb_header_rec_rdb' ...
    num2str(revision) '(pfile_name,0));'];
eval(main_header_cmd);

% Add the exam header
main_exam_cmd = ['header = setfield(header, ''exam'', ge_read_exam_header_rdb' ...
    num2str(revision) '(pfile_name,header.rdb.rdb_hdr_off_exam));'];
eval(main_exam_cmd);

% Add the series header
main_series_cmd = ['header = setfield(header, ''series'', ge_read_series_header_rdb' ...
    num2str(revision) '(pfile_name,header.rdb.rdb_hdr_off_series));'];
eval(main_series_cmd);

% Add the image header
main_image_cmd = ['header = setfield(header, ''image'', ge_read_image_header_rdb' ...
    num2str(revision) '(pfile_name,header.rdb.rdb_hdr_off_image));'];
eval(main_image_cmd);
