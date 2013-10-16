% Check that root folder can be written to

function backupPfiles(import_dir, organized_dir, varargin)

if(nargin>2)
    can_softlink = varargin{1};
    if(nargin > 3)
        can_md5sum = varargin{2};
    else
        % Check if the computer has the ability to perform md5sums
        if(ispc)
            [status path] = system('where md5sum');
        else
            [status path] = system('which md5sum');
        end
        can_md5sum = ~status; % if successful, status=0
    end
else
    % Check if the computer has the ability to softlink
    if(ispc)
        [status path] = system('where ln');
    else
        [status path] = system('which ln');
    end
    can_softlink = ~status; % if successful, status=0
end

% Define UIDs of all recognized systems
recognized_UIDs    = {'0000000919684onc','0000919684micro2'};
recognized_systems = {'lx-ron1',         'onnes'};

%Find all the files in backup_dir for backup
files_to_backup = ls([import_dir filesep() 'P*.7']);
if(length(files_to_backup)<1)
    return;
end

% Read in every pfile
num_pfiles = size(files_to_backup,1);
for(i=1:num_pfiles)
    pfilename = [import_dir filesep() files_to_backup(i,:)];
    if(~exist(pfilename))
        errormsg(['Pfile (' pfilename ') does not exist.']);
    end
    [exam_timestamp, series_timestamp, subject_id, ...
        scan_identifier, ex_no, se_no, series_descr, system_str] = ...
        getPfileInfo(pfilename, recognized_UIDs, recognized_systems);
    
    dir_name = [organized_dir filesep()];
    
    % Create system directory if necessary
    dir_name= createDir(dir_name, system_str);
    
    %% Create Date main directory
    date_dir_name = createDir(dir_name, 'date');
    
    % Create directory with date of scan
    date_dir_name = createDir(date_dir_name, exam_timestamp);
    
    % Create series directory
    if(length(series_descr)>0)
        series_name = ['Series' num2str(se_no) '_' series_descr];
    else
        series_name = ['Series' num2str(se_no)];
    end
    date_dir_name = createDir(date_dir_name, series_name);
    
    %Move pfile to series directory
    pfile = [import_dir filesep() files_to_backup(i,:)];
    pfile_new_loc = [date_dir_name files_to_backup(i,:)];
    if(exist(pfile_new_loc))
        % Get all similar files
        similar_files = ls([pfile_new_loc '*']);
        
        % Check if the file is new (no need for duplicates!)
        same_file = 0;
        if(can_md5sum)
            n_files = nrow(similar_files);
            versions = zeros(1,n_files);
            
            for i=1:n_files
                cur_file = [import_dir filesep() deblank(similar_files(i,:))];
                same_file = sameFile(pfile_new_loc, cur_file);
                if(same_file)
                    break; % no need to keep looking, its a duplicate!
                end
            end
        end
        
        % If the files are different, add a number to the file
        if(~same_file)
            disp('Adding version number!');
            pfile_new_loc = addVersionNumber(date_dir_name, files_to_backup(i,:), similar_files);
        else
            disp('FOUND DUPLICATE!');
        end
    end
    movefile(pfile,pfile_new_loc,'f');
    
    %% Create Subject directory
    if(~isempty(subject_id) && can_softlink)
        subject_dir_name = createDir(dir_name, 'subject');
        
        % Add directory for subject number
        subject_dir_name = createDir(subject_dir_name, subject_id);
        
        % If a scan identifier exists, make a directory for it
        if(~isempty(scan_identifier))
            subject_dir_name = createDir(subject_dir_name, scan_identifier);
        end
        
        % Create series directory if necessary
        subject_dir_name = createDir(subject_dir_name, series_name);
        
        pfile_new_loc_subject = [subject_dir_name files_to_backup(i,:)];
        make_soft_link = 1;
        if(exist(pfile_new_loc_subject))
            % Get all similar files
            similar_files = ls([pfile_new_loc_subject '*']);
            
            % Check if the file is new (no need for duplicates!)
            same_file = 0;
            if(can_md5sum)
                n_files = nrow(similar_files);
                versions = zeros(1,n_files);
                
                for i=1:n_files
                    cur_file = [subject_dir_name deblank(similar_files(i,:))];
                    deblank(similar_files(i,:));
                    same_file = sameFile(pfile_new_loc_subject, cur_file);
                    if(same_file)
                        break; % no need to keep looking, its a duplicate!
                    end
                end
            end
            
            % If the files are different, add a number to the file
            if(~same_file)
                disp('Adding version number!');
                pfile_new_loc_subject = addVersionNumber(date_dir_name, files_to_backup(i,:), similar_files);
            else
                make_soft_link = 0;
                disp('FOUND DUPLICATE!');
            end
        end
        
        % Dont make duplicate soft links
        if(make_soft_link)
            % Put a soft link back to the actual file
            makeSoftlink(pfile_new_loc,pfile_new_loc_subject);
        end
    end
end
end %function

function [exam_timestamp, series_timestamp, subject_id, ...
    scan_identifier, ex_no, se_no, series_descr, system_str] = ...
    getPfileInfo(pfilename, recognized_UIDs, recognized_systems)
%Read header and unique series identifier
if(~exist(pfilename))
    errormsg(['Pfile (' pfilename ') does not exist.']);
end
[revision, logo] = ge_read_rdb_rev_and_logo(pfilename);
header = ge_read_header(pfilename, revision);

ex_no = header.exam.ex_no;
se_no = header.series.se_no;

systemUID = deblank(header.exam.uniq_sys_id');
if(any(ismember(recognized_UIDs,systemUID)))
    system_str = recognized_systems{ismember(recognized_UIDs,systemUID)};
else
    system_str = systemUID;
end

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

% Make sure patient id fits naming convention
regexp_result =  regexp(pat_id,'(\d+-\d+)([a-zA-Z]*)','tokens');
if(~isempty(regexp_result))
    subject_id = regexp_result{1}{1};
    scan_identifier = regexp_result{1}{2};
else
    subject_id = [];
    scan_identifier = [];
end

series_descr = deblank(header.series.se_desc');
end

% Creates a directory only if it doesn't exist
function [output_dir_name]= createDir(parent_dir, dir_name)
% Replace all non supported characters with underscores
dir_name=regexprep(dir_name, '[^a-zA-Z_0-9]', '_');

output_dir_name = [parent_dir dir_name filesep()];
% Check if directory exists
if(~exist(output_dir_name,'dir'))
    mkdir(parent_dir,dir_name);
end
end

% Makes a soft link to an existing file
function makeSoftlink(existingFile,link_name)
system(['ln -s "' existingFile '" "' link_name '"']);
end

function newFullPath = addVersionNumber(dir_name, file_name, similar_files)
% Calculate version numbers of each file
n_files = nrow(dir_elements);
versions = zeros(1,n_files);
for i=1:n_files
    cur_file = similar_files(i,:);
    regexp_result =  regexp(cur_file,...
        ['.*' filesep() 'P.*7\((.*)\)'],'tokens');
    if(~isempty(regexp_result))
        regexp_result = str2num(regexp_result{1});
    else
        regexp_result = 1; % Assume its the first version
    end
    versions(i) = regexp_result;
end

% Check for the lowest version that does not exist
lowest_version = n_files+1;
for i=1:n_files
    if(~any(versions==i))
        lowest_version = i;
        break;
    end
end

% Create new filename with version number
newFullPath = [dir_name file_name '(' lowest_version ')'];
end

function errormsg(msg)
error(['ERROR - ' msg ' BACKUP UNSUCCESSFUL. Please try again.'])
end