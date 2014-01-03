%% TODO Check that root folder can be written to

function backupPfiles(import_dir, organized_dir, varargin)
% Check input arguments
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
dir_name = [organized_dir filesep()];
num_pfiles = size(files_to_backup,1);
for(i=1:num_pfiles)
    % Check that file exists
    pfilename = [import_dir filesep() files_to_backup(i,:)];
    if(~exist(pfilename))
        errormsg(['Pfile (' pfilename ') does not exist.']);
    end
    
    % Get info from header
    pfile_info = getPfileInfo(pfilename, recognized_UIDs, recognized_systems);
    pfile_info.pfile_base = strtrim(deblank(files_to_backup(i,:)));
    pfile_info.import_dir = import_dir;
    
    % Create system directory if necessary
    system_dir= createDir(dir_name, pfile_info.system_str);

    
    % Create Organized By Date Directory
    useSoftLinks = 0; % Actually move file to organized by date directory
    pfile_info = createDirectoryOrganizedByDate(system_dir,pfile_info, useSoftLinks, can_md5sum); 
    
    if(can_softlink & isfield(pfile_info,'data_loc')) % Data loc is only stored if new data was written, no need to worry about dups
        useSoftLinks = 1; % Use softlinks for all other organized folders
        
        % Create OrganizedBySubject directory
        if(~isempty(pfile_info.subject_id) && ~isempty(pfile_info.subject_group))
            pfile_info = createDirectoryOrganizedBySubject(system_dir,pfile_info, useSoftLinks, can_md5sum);
        end
        
        %% Create OrganizedByOperator directory
        if(~isempty(pfile_info.operator))
            pfile_info = createDirectoryOrganizedByOperator(system_dir,pfile_info, useSoftLinks, can_md5sum);
        end
        
        %% Create OrganizedByStudy directory
        if(~isempty(pfile_info.study))
            pfile_info = createDirectoryOrganizedByStudy(system_dir,pfile_info, useSoftLinks, can_md5sum);
        end
    end
end
end %function

function pfile_info = getPfileInfo(pfilename, recognized_UIDs, recognized_systems)
%Read header and unique series identifier
if(~exist(pfilename))
    errormsg(['Pfile (' pfilename ') does not exist.']);
end
[revision, logo] = ge_read_rdb_rev_and_logo(pfilename);
header = ge_read_header(pfilename, revision);

pfile_info.ex_no = header.exam.ex_no;
pfile_info.se_no = header.series.se_no;

systemUID = strtrim(deblank(header.exam.uniq_sys_id'));
if(any(ismember(recognized_UIDs,systemUID)))
    pfile_info.system_str = recognized_systems{ismember(recognized_UIDs,systemUID)};
else
    pfile_info.system_str = systemUID;
end

if(header.exam.ex_datetime == 0)
    %Create exam and series dates in YYYY_MM_DD_HH_MM_SS format
    exam_timestamp = [str2num(['20' header.rdb.rdb_hdr_scan_date(8:9)']), ...
        str2num(header.rdb.rdb_hdr_scan_date(1:2)'), ...
        str2num(header.rdb.rdb_hdr_scan_date(4:5)'), ...
        str2num(header.rdb.rdb_hdr_scan_time(1:2)'), ...
        str2num(header.rdb.rdb_hdr_scan_time(4:5)'), 0];
    exam_timestamp = datestr(exam_timestamp,'yyyy mmm dd HH_MM');
    pfile_info.exam_year = ['year_' exam_timestamp(1:4)];
    pfile_info.exam_month = ['month_' header.rdb.rdb_hdr_scan_date(1:2)' '_' exam_timestamp(6:8)];
    pfile_info.exam_day = ['day_' exam_timestamp(10:11)];
    pfile_info.exam_time = ['time_hh_mm_' exam_timestamp(13:17)];
else
    date_number = header.exam.ex_datetime/86400 + datenum(1970,1,1);
    exam_timestamp = datestr(date_number,'yyyy mmm dd HH_MM');
    pfile_info.exam_year = ['year_' exam_timestamp(1:4)];
    pfile_info.exam_month = ['month_' datestr(date_number,'mm') '_' exam_timestamp(6:8)];
    pfile_info.exam_day = ['day_' exam_timestamp(10:11)];
    pfile_info.exam_time = ['time_hh_mm_' exam_timestamp(13:17)];
end


if(header.series.se_datetime == 0)
    pfile_info.series_timestamp = backup_timestamp;
else
    pfile_info.series_timestamp = datestr(header.series.se_datetime/86400 + datenum(1970,1,1),'yyyymmddHHMM');
end

%Should be the same
pat_id = strtrim(deblank(header.exam.patid'));
pat_id2 = strtrim(deblank(header.exam.patname'));
if(isempty(pat_id) && ~isempty(pat_id2))
    pat_id = pat_id2;
end

% Make sure patient id fits naming convention
regexp_result =  regexp(pat_id,'(\d+)-(\d+)([a-zA-Z]*)','tokens');
if(~isempty(regexp_result))
%     pfile_info.subject_id 
    pfile_info.subject_group = regexp_result{1}{1};
    pfile_info.subject_id = regexp_result{1}{2};
    pfile_info.scan_identifier = regexp_result{1}{3};
else
    pfile_info.subject_id = [];
    scan_identifier = [];
end

pfile_info.series_descr = strtrim(deblank(header.series.se_desc'));

pfile_info.operator = strtrim(deblank(header.exam.op'));
pfile_info.study = strtrim(deblank(header.exam.ex_desc'));

pfile_info.pfilename = pfilename;
end

% Creates a directory only if it doesn't exist
function [output_dir_name]= createDir(parent_dir, dir_name)
% Replace all non supported characters with underscores
dir_name=regexprep(strtrim(deblank(dir_name)), '[^a-zA-Z_0-9]', '_');

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
n_files = nrow(similar_files);
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

function pfile_info = createDirectoryOrganizedByDate(root_dir,pfile_info,softLinkFile, can_md5sum)
    % Create 'ByDate' folder
    dir_name = createDir(root_dir, 'ByDate');
    
    % Create directory with date of scan
    date_dir_name = createDir(dir_name,pfile_info.exam_year);
    date_dir_name = createDir(date_dir_name,pfile_info.exam_month);
    date_dir_name = createDir(date_dir_name,pfile_info.exam_day);
    date_dir_name = createDir(date_dir_name,pfile_info.exam_time);
    
    % Create series directory
    pfile_info = createSeriesDirectory(date_dir_name,pfile_info, softLinkFile, can_md5sum); 
end


function pfile_info = createDirectoryOrganizedByOperator(root_dir,pfile_info, softLinkFile, can_md5sum)
        % Create directory for operator
        operator_dir_name = createDir(root_dir, 'ByOperator');
        
        % Add directory for operator
        operator_dir_name = createDir(operator_dir_name, pfile_info.operator);
        
        % Add organized by date folder
        pfile_info = createDirectoryOrganizedByDate(operator_dir_name,pfile_info,softLinkFile, can_md5sum);
        
        % Add organized by subject directory
        pfile_info = createDirectoryOrganizedBySubject(operator_dir_name,pfile_info, softLinkFile, can_md5sum);
end
        
function pfile_info = createDirectoryOrganizedByStudy(root_dir,pfile_info, softLinkFile, can_md5sum)
    if(~isempty(pfile_info.study))
        % Create directory for study
        study_dir_name = createDir(root_dir, 'ByStudy');
        
        % Add directory for study
        study_dir_name = createDir(study_dir_name, pfile_info.study);
        
        % Add organized by date folder
        pfile_info = createDirectoryOrganizedByDate(study_dir_name,pfile_info,softLinkFile, can_md5sum);
        
        % Add organized by subject directory
        pfile_info = createDirectoryOrganizedBySubject(study_dir_name,pfile_info, softLinkFile, can_md5sum);
        
        % Add organized by operator directory
        pfile_info = createDirectoryOrganizedByOperator(study_dir_name,pfile_info, softLinkFile, can_md5sum);
    end
end

function pfile_info = createDirectoryOrganizedBySubject(root_dir,pfile_info, softLinkFile, can_md5sum)
if(~isempty(pfile_info.subject_group) && ~isempty(pfile_info.subject_id))
    % Create directory for subject
    subject_dir_name = createDir(root_dir, 'OrganizedBySubject');
    
    % Add directory for subject group
    subject_dir_name = createDir(subject_dir_name, pfile_info.subject_group);
    
    % Add directory for subject number
    subject_dir_name = createDir(subject_dir_name, pfile_info.subject_id);
    
    % If a scan identifier exists, make a directory for it
    if(~isempty(pfile_info.scan_identifier))
        subject_dir_name = createDir(subject_dir_name, pfile_info.scan_identifier);
    end
    
    % Create series directory and move pfile there
     pfile_info = createSeriesDirectory(subject_dir_name,pfile_info, softLinkFile, can_md5sum);   
end
end

function pfile_info = createSeriesDirectory(root_dir,pfile_info,softLinkFile, can_md5sum)
    % Create series directory
    series_name = ['Series' num2str(pfile_info.se_no)];
    if(length(pfile_info.series_descr)>0)
        series_name = [series_name '_' strtrim(deblank(pfile_info.series_descr))];
    end
    
    % Create series directory
    series_dir_name = createDir(root_dir, series_name);
    
    % Move pfile to series directory
    pfile_info = movePfile(series_dir_name, pfile_info, softLinkFile, can_md5sum);
end

function pfile_info = movePfile(pfile_new_dir, pfile_info, softLinkFile, can_md5sum)
    pfile = pfile_info.pfilename;
    %Move pfile to series directory
    unique_file = 1;
    pfile_new_loc = [pfile_new_dir pfile_info.pfile_base];
    if(exist(pfile_new_loc))
        % Get all similar files
        similar_files = ls([pfile_new_loc '*']);
        
        % Check if the file is new (no need for duplicates!)
        same_file = 0;
        if(can_md5sum)
            n_files = nrow(similar_files);
            versions = zeros(1,n_files);
            
            for i=1:n_files
                cur_file = [pfile_info.import_dir filesep() strtrim(deblank(similar_files(i,:)))];
                same_file = sameFile(pfile_new_loc, cur_file);
                if(same_file)
                    break; % no need to keep looking, its a duplicate!
                end
            end
        end
        
        % If the files are different, add a number to the file
        if(~same_file)
            cprintf('Comments','Adding version number!\n');
            pfile_new_loc = addVersionNumber(pfile_new_dir, pfile_info.pfile_base, similar_files);
            
        else
            unique_file = 0;
        end
    end
    
    if(unique_file);
        if(softLinkFile)
            if(isfield(pfile_info,'data_loc'))                
                makeSoftlink(pfile_info.data_loc, pfile_new_loc);
            else
                error('No dataloc!');
            end
        else
            % Actually copy file
            copyfile(pfile,pfile_new_loc,'f');
            
            pfile_info.data_loc = pfile_new_loc;
            
            % Make sure the file made it ok (md5sum check)
            if(~sameFile(pfile,pfile_new_loc))
                error(['md5sum error between ' pfile ' and ' pfile_new_loc]);
            end
            
            % Remove tmp file
            delete(strtrim(deblank(pfile)));
        end
    else
        % Announce that its not a unique file
        cprintf('Comments','Found duplicate file for %s, so not backing it up again.\n', pfile_info.pfilename);
        
        % Delete duplicates
        delete(strtrim(deblank(pfile_info.pfilename)));
    end
end