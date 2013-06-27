function backupPfiles(import_dir, organized_dir)
% organized_dir = 'E:\pfiles\';
% import_dir = [organized_dir 'import\'];

%Find all the files in backup_dir for backup
files_to_backup = ls([import_dir filesep() 'P*.7']);
files_to_backup = files_to_backup(3:end,:);
if(length(files_to_backup)<1)
    return;
end

% Read in every pfile
num_pfiles = size(files_to_backup,1);
for(i=1:num_pfiles)
    pfilename = [import_dir files_to_backup(i,:)];
    if(~exist(pfilename))
        errormsg(['Pfile (' pfilename ') does not exist.']);
    end
    [exam_timestamp, series_timestamp, series_uid, pat_id, ex_no, se_no, ...
        series_descr] = getPfileInfo(pfilename);
    
    % Create exam directory if necessary
    exam_dir_name = [organized_dir filesep()];
    if(length(pat_id)>0)
        exam_dir_name = [exam_dir_name 'SUBJECT_' pat_id];
    else
        exam_dir_name = [exam_dir_name 'ANON'];
    end
    exam_dir_name = [exam_dir_name '_' num2str(ex_no) '_' exam_timestamp ];
    
    if(~exist(exam_dir_name,'dir'))
        mkdir(exam_dir_name);
        system(['touch -t ' exam_timestamp ' ' char(39) exam_dir_name char(39)]);
    end
    
    
    % Create series directory if necessary
    series_dir_name = [exam_dir_name filesep() num2str(se_no)];
    if(length(series_descr)>0)
        series_dir_name = [series_dir_name '_' series_descr];
    end
    if(~exist(series_dir_name,'dir'))
        mkdir(series_dir_name);
        system(['touch -t ' series_timestamp ' ' char(39) series_dir_name char(39)]);
    end
    
    %Move pfile to series directory
    pfile = [import_dir  files_to_backup(i,:)];
    movefile(pfile,series_dir_name,'f');
    newFilePath = [series_dir_name filesep() files_to_backup(i,:)];
    system(['touch -t ' series_timestamp ' ' char(39) newFilePath char(39)]);
end
end %function

function [exam_timestamp, series_timestamp, series_uid, pat_id, ...
    ex_no, se_no, series_descr] = getPfileInfo(pfilename)
% Parameters that almost never change.
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
precision='int16';      % Can we read this from header? CSI extended mode uses int32

%Read header and unique series identifier
if(~exist(pfilename))
    errormsg(['Pfile (' pfilename ') does not exist.']);
end
header = ge_read_header(pfilename, hdr_off, byte_order);
series_uid = deblank(header.series.series_uid');

ex_no = header.exam.ex_no;
se_no = header.series.se_no;

%Create exam and series dates in YYYY_MM_DD_HH_MM_SS format
year = header.rdb.rdb_hdr_scan_date(8:9)';
month = header.rdb.rdb_hdr_scan_date(1:2)';
day = header.rdb.rdb_hdr_scan_date(4:5)';
hour = header.rdb.rdb_hdr_scan_time(1:2)';
minute = header.rdb.rdb_hdr_scan_time(4:5)';
backup_timestamp = ['20' num2str(year) num2str(month) num2str(day) ...
    num2str(hour)  num2str(minute) ];

if(header.exam.ex_datetime == 0)
    exam_timestamp = backup_timestamp;
else
    exam_timestamp = datestr(header.exam.ex_datetime/86400 + datenum(1970,1,1),'yyyymmddHHMM');
end

if(header.series.se_datetime == 0)
    series_timestamp = backup_timestamp;
else
    series_timestamp = datestr(header.series.se_datetime/86400 + datenum(1970,1,1),'yyyymmddHHMM');
end

%Should be the same
pat_id = deblank(header.exam.patid');
pat_id2 = deblank(header.exam.patname');
if(isempty(pat_id) && ~isempty(pat_id2))
    pat_id = pat_id2;
end

series_descr = deblank(header.series.se_desc');
end

function errormsg(msg)
error(['ERROR - ' msg ' BACKUP UNSUCCESSFUL. Please try again.'])
end