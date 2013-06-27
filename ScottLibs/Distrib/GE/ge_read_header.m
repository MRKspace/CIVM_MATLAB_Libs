function header = ge_read_header(pfile_name, revision, hdr_off, byte_order, precision)

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

% Add the main header
main_header_cmd = ['header = struct(''rdb'', ge_read_rdb_header_rec_rdb' ...
    num2str(revision) '(pfile_name,hdr_off,byte_order));'];
eval(main_header_cmd);
% header = struct('rdb', ge_read_rdb_header_rec(pfile_name,hdr_off,byte_order));

% Add the exam header
main_exam_cmd = ['header = setfield(header, ''exam'', ge_read_exam_header_rdb' ...
    num2str(revision) '(pfile_name,header.rdb.rdb_hdr_off_exam,byte_order));'];
eval(main_exam_cmd);
% header = setfield(header, 'exam', ge_read_exam_header(pfile_name, ...
%     header.rdb.rdb_hdr_off_exam, byte_order));

% Add the series header
main_series_cmd = ['header = setfield(header, ''series'', ge_read_series_header_rdb' ...
    num2str(revision) '(pfile_name,header.rdb.rdb_hdr_off_series,byte_order));'];
eval(main_series_cmd);
% header = setfield(header, 'series', ge_read_series_header(pfile_name, ...
%     header.rdb.rdb_hdr_off_series, byte_order));

% Add the image header
main_image_cmd = ['header = setfield(header, ''image'', ge_read_image_header_rdb' ...
    num2str(revision) '(pfile_name,header.rdb.rdb_hdr_off_image,byte_order));'];
eval(main_image_cmd);
% header = setfield(header, 'image', ge_read_image_header(pfile_name, ...
%     header.rdb.rdb_hdr_off_image, byte_order));
