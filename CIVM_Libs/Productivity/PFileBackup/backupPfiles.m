%% TODO Check that root folder can be written to

function backupPfiles(import_dir, organized_dir, varargin)
% Check input arguments
if(nargin>2)
    can_link = varargin{1};
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
    % Check if the computer has the ability to link
    if(ispc)
        [status path] = system('where ln');
    else
        [status path] = system('which ln');
    end
    can_link = ~status; % if successful, status=0
end

%Find all the files in backup_dir for backup
files_to_backup = ls([import_dir filesep() 'P*.7']);
if(length(files_to_backup)<1)
    return;
end

byDate = BackupByDate();
bySubject = BackupBySubject();
byOperator = BackupByOperator();
bySeries = BackupBySeries();

% Read in every pfile
dir_name = [organized_dir filesep()];
num_pfiles = size(files_to_backup,1);
for(i=1:num_pfiles)
    % Check that file exists
    pfile.base = strtrim(deblank(files_to_backup(i,:)));
    pfile.import_dir = import_dir;
    pfile.import_file = [import_dir filesep() pfile.base];
    if(~exist( pfile.import_file))
        errormsg(['Pfile ('  pfile.import_file ') does not exist.']);
    end
    
    % Get info from header
    [revision, logo] = ge_read_rdb_rev_and_logo(pfile.import_file);
    header = ge_read_header(pfile.import_file, revision);
    
    % Backup file
    pfile = byDate.backup(pfile, dir_name, header, 0, can_md5sum); % Actually move file to organized by date director
    if(can_link & ~pfile.isduplicate)
        pfile = bySubject.backup(pfile, dir_name, header, 1, can_md5sum);
        pfile = byOperator.backup(pfile, dir_name, header, 1, can_md5sum);
        pfile = bySeries.backup(pfile, dir_name, header, 1, can_md5sum);
    end
end
end %function

function errormsg(msg)
error(['ERROR - ' msg ' BACKUP UNSUCCESSFUL. Please try again.'])
end

