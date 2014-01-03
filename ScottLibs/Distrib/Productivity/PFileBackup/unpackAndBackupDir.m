function unpackAndBackupDir(varargin)
% Default to create all folders
needs_backupdir = 1;
needs_tmpdir = 1;
needs_organizeddir = 1;
regex_str = 'P*.7';

% Check input arguments
showRestartText = 1;
if(nargin>0)
    dir_to_backup = varargin{1};
    needs_backupdir = ~exist(dir_to_backup);
    
    if(nargin > 1)
        tmp_import_dir = varargin{2};
        needs_tmpdir = ~exist(tmp_import_dir);
        
        if(nargin > 2)
            organized_dir = varargin{3};
            needs_organizeddir = ~exist(organized_dir);

            if(nargin > 3)
                showRestartText = varargin{4};
            end
        end
    end
end

if(needs_backupdir)
    dir_to_backup = uigetdir('.','Select directory to backup')
end
if(needs_tmpdir)
    tmp_import_dir = uigetdir('.','Select temporary import dir')
end
if(needs_organizeddir)
    organized_dir = uigetdir('.','Select organized dir')
end

if(showRestartText)
    % Announce start of backup
    disp(['Backup of ' dir_to_backup ' has begun...']);
    
    % provide easy way to restart
    disp(['To restart backup:']);
    disp(['unpackAndBackupDir(''' dir_to_backup ''',''' tmp_import_dir ...
        ''',''' organized_dir ''');']);
end

% Change to the temp dir to keep things clean
starting_dir = pwd();
cd(tmp_import_dir);

% Check if the computer has the ability to softlink
if(ispc)
    [status path] = system('where ln');
else
    [status path] = system('which ln');
end
can_softlink = ~status; % if successful, status=0

% Check if the computer has the ability to perform md5sums
if(ispc)
    [status path] = system('where md5sum');
else
    [status path] = system('which md5sum');
end
can_md5sum = ~status; % if successful, status=0

% Make sure its a directory that exists
assertExistence(dir_to_backup);
if(~isdir(dir_to_backup))
    error(['Not a directory:' dir_to_backup]);
end

% Get a list of everything in the directory
dir_elements = ls(dir_to_backup);
if(size(dir_elements,1)<3)
    cprintf('SystemCommands','Backup Directory (%s) empty!\n', dir_to_backup);
    return;
end
dir_elements = dir_elements(3:end,:);

% Get a list of matching files in the directory
dir_pfiles = ls([dir_to_backup filesep() regex_str]);
if(size(dir_pfiles,1)>0)
    % Loop through pfiles and back them up
    numPfiles = size(dir_pfiles, 1);
    for i=1:numPfiles
        cur_pfile = strtrim(deblank([dir_to_backup filesep() dir_pfiles(i,:)]));
        
        % Double check the pfile exists
        assertExistence(cur_pfile);
        
        % Copy pfile to import dir
        copyfile(cur_pfile,tmp_import_dir);
        
        % Check that copy worked (md5sum)
        moved_pfile = strtrim(deblank([tmp_import_dir filesep() dir_pfiles(i,:)]));        
        if(~sameFile(moved_pfile, cur_pfile))
            error(['md5sum failed when moving ' cur_pfile ' to ' moved_pfile]);
        end
    end
    
    
    % Back up all Pfiles
    backupPfiles(tmp_import_dir, organized_dir, can_softlink, can_md5sum);
end

% Loop through everything in the directory and deal with it
numElements = size(dir_elements, 1);
for i=1:numElements
    cur_element = strtrim(deblank([dir_to_backup filesep() dir_elements(i,:)]));
    
    % Double check the element exists
    assertExistence(cur_element);
    
    % Check filetype and deal with it
    if(isdir(cur_element))
        % Announce recursion
        cprintf('Comments','Recursing to %s...\n',cur_element);
        
        % If its a directory, recurse
        unpackAndBackupDir(cur_element,tmp_import_dir, organized_dir, 0);
    else
        % Break up the filename
        [pathstr, name, ext] = fileparts(cur_element);
        
        switch ext
            case '.tar'
                % Announce tar unpack
                cprintf('Comments','Unpacking tar file %s...\n',cur_element);
        
                % Make temp dir to untar files
                tmp_dir = ['tmp_' name];
                mkdir(tmp_dir);
                
                % Untar files
                untar(cur_element,tmp_dir);
                
                % Deal with files
                cprintf('Comments','Recursing in %s...\n',cur_element);
                unpackAndBackupDir(tmp_dir,tmp_import_dir, organized_dir, 0);
                
                % Delete tmp dir
                rmdir(tmp_dir,'s');
            case '.zip'
                % Announce unzipping
                cprintf('Comments','Unzipping zip file %s...\n', cur_element);

                % Make temp dir to unzip files
                tmp_dir = ['tmp_' name];
                mkdir(tmp_dir)
                
                % Unzip files
                unzip(cur_element,tmp_dir);
                disp(['Recursing in ' cur_element]);
                
                % Deal with files
                unpackAndBackupDir(tmp_dir,tmp_import_dir, organized_dir, 0);
                
                % Delete tmp dir
                rmdir(tmp_dir,'s');
            case '.7'
                % Should have already been backed up
            otherwise
                cprintf('Error','UNSUPPORTED FILE (not backing up):%s\n', cur_element);
        end
    end
    
end

% Go back to starting dir
cd(starting_dir);
end

function assertExistence(filename)
if(~exist(filename))
    error(['Does not exist:' filename]);
end
end
