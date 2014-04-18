function unpackAndBackupDir(delete_after, varargin)
% Default to create all folders
needs_backupdir = 1;
needs_tmpdir = 1;
needs_organizeddir = 1;
regex_str = 'P*.7';

% Check input arguments
showRestartText = 1;
if(nargin>1)
    dir_to_backup = varargin{1};
    needs_backupdir = ~exist(dir_to_backup);
    
    if(nargin > 2)
        tmp_import_dir = varargin{2};
        needs_tmpdir = ~exist(tmp_import_dir);
        
        if(nargin > 3)
            organized_dir = varargin{3};
            needs_organizeddir = ~exist(organized_dir);
            
            if(nargin > 4)
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
    can_softlink = ~status; % if successful, status=0
    
    if(~can_softlink)
        % Try unix style in case of cygwin weirdness
        [status path] = system('which ln');
    end
else
    [status path] = system('which ln');
end
can_softlink = ~status; % if successful, status=0

% Check if the computer has the ability to perform md5sums
if(ispc)
    [status path] = system('where md5sum');
    can_md5sum = ~status; % if successful, status=0
    
    if(~can_md5sum)
        % Try unix style in case of cygwin weirdness
        [status path] = system('which md5sum');
    end
else
    [status path] = system('which md5sum');
end
can_md5sum = ~status; % if successful, status=0

% Make sure its a directory that exists
assertExistence(dir_to_backup);
if(~isdir(dir_to_backup))
    warning(['Not a directory:' dir_to_backup]);
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
        if(assertExistence(cur_pfile))
            % Copy pfile to import dir
            copyfile(cur_pfile,tmp_import_dir);
            
            % Check that copy worked (md5sum)
            moved_pfile = strtrim(deblank([tmp_import_dir filesep() dir_pfiles(i,:)]));
            same_file = 0;
            fail_count = 0;
            while(~same_file && fail_count < 5)
                % Sometimes this fails the first time, so try 5 times..
                same_file  = sameFile(moved_pfile, cur_pfile);
                fail_count = fail_count+1;
            end
            if(~same_file)
                error(['md5sum failed when moving ' cur_pfile ' to ' moved_pfile]);
            end
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
    if(assertExistence(cur_element))
        
        % Check filetype and deal with it
        if(isdir(cur_element))
            % Announce recursion
            cprintf('Comments','Recursing to %s...\n',cur_element);
            
            % If its a directory, recurse
            unpackAndBackupDir(delete_after, cur_element,tmp_import_dir, organized_dir, 0);
            
            if(delete_after)
                system(['rm -rf ' cur_element]);
            end
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
                    unpackAndBackupDir(delete_after, tmp_dir,tmp_import_dir, organized_dir, 0);
                    
                    % Delete tmp dir
                    rmdir(tmp_dir,'s');
                    
                    if(delete_after)
                        delete(cur_element);
                    end
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
                    unpackAndBackupDir(delete_after, tmp_dir,tmp_import_dir, organized_dir, 0);
                    
                    % Delete tmp dir
                    rmdir(tmp_dir,'s');
                    
                    if(delete_after)
                        delete(cur_element);
                    end
                case '.7'
                    % Should have already been backed up
                    if(delete_after)
                        delete(cur_element);
                    end
                otherwise
                    cprintf('Error','UNSUPPORTED FILE (not backing up):%s\n', cur_element);
            end
        end
    end
    
end

% Go back to starting dir
cd(starting_dir);
end

function does_exist = assertExistence(filename)
does_exist = exist(filename)
if(~does_exist)
    warning(['Does not exist:' filename]);
end
end
