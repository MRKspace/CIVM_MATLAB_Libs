function unpackAndBackupDir(dir_to_backup, tmp_import_dir, organized_dir)
if(isempty(dir_to_backup))
    dir_to_backup = uigetdir('.','Select directory to backup')
end

if(isempty(tmp_import_dir))
    tmp_import_dir = uigetdir('.','Select temporary import dir')
end

if(isempty(organized_dir))
    organized_dir = uigetdir('.','Select organized dir')
end

% tmp_import_dir = 'E:\pfiles\import';
% backup_script = 'E:\scripts\backupPfiles.exe';

% Make sure its a directory that exists
assertExistence(dir_to_backup);
if(~isdir(dir_to_backup))
    error(['Not a directory:' dir_to_backup]);
end

% Get a list of everything in the directory
dir_elements = ls(dir_to_backup);
if(size(dir_elements,1)<3)
    disp(['Empty Directory:' dir_to_backup]);
    return;
end
dir_elements = dir_elements(3:end,:);

% Get a list of Pfiles
% Get a list of everything in the directory
dir_pfiles = ls([dir_to_backup filesep() 'P*.7']);
if(size(dir_pfiles,1)>0)
    % Loop through pfiles and back them up
    numPfiles = size(dir_pfiles, 1);
    for i=1:numPfiles
        cur_pfile = deblank([dir_to_backup filesep() dir_pfiles(i,:)]);
        
        % Double check the pfile exists
        assertExistence(cur_pfile);
        
        % Move pfile to import dir
        copyfile(cur_pfile,tmp_import_dir);
    end
    
    
    % Back up all Pfiles
%     system(backup_script);
	backupPfiles(tmp_import_dir, organized_dir);
end

% Loop through everything in the directory and deal with it
numElements = size(dir_elements, 1);
for i=1:numElements
    cur_element = deblank([dir_to_backup filesep() dir_elements(i,:)]);
    
    % Double check the element exists
    assertExistence(cur_element);
    
    % Check filetype and deal with it
    if(isdir(cur_element))
        % If its a directory, recurse
        unpackAndBackupDir(cur_element,tmp_import_dir, organized_dir);
    else
        % Break up the filename
        [pathstr, name, ext] = fileparts(cur_element);
        
        switch ext
            case '.tar'
                % Make temp dir to untar files
                tmp_dir = ['tmp_' name];
                mkdir(tmp_dir);
                
                % Untar files
                untar(cur_element,tmp_dir);
                
                % Deal with files
                unpackAndBackupDir(tmp_dir,tmp_import_dir, organized_dir);
                
                % Delete tmp dir
                rmdir(tmp_dir,'s');
            case '.zip'
                % Make temp dir to unzip files
                tmp_dir = ['tmp_' name];
                mkdir(tmp_dir)
                
                % Unzip files
                unzip(cur_element,tmp_dir);
                
                % Deal with files
                unpackAndBackupDir(tmp_dir,tmp_import_dir, organized_dir);
                
                % Delete tmp dir
                rmdir(tmp_dir,'s');
            case '.7'
                % Should have already been backed up
            otherwise
                disp(['UNSUPPORTED FILE (not backing up):' cur_element]);
        end
    end
    
end
end

function assertExistence(filename)
if(~exist(filename))
    error(['Does not exist:' filename]);
end
end
