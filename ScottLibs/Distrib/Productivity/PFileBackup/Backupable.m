classdef Backupable
    properties
        % Define UIDs of all recognized systems
        recognized_UIDs    = {'0000000919684onc','0000919684micro2'};
        recognized_systems = {'lx-ron1',         'onnes'};
        system;
        data_loc;
    end
    
    methods
        % Creates a directory only if it doesn't exist
        function [output_dir_name]= createDir(obj, parent_dir, dir_name)
            % Replace all non supported characters with underscores
            dir_name=regexprep(strtrim(deblank(dir_name)), '[^a-zA-Z_0-9]', '_');
            
            output_dir_name = [parent_dir dir_name filesep()];
            
            % Check if directory exists
            if(~exist(output_dir_name,'dir'))
                mkdir(parent_dir,dir_name);
            end
        end
        
        function root_dir = createRootDir(obj, root_dir, header)
            % Get name of system
            systemUID = strtrim(deblank(header.exam.uniq_sys_id'));
            if(any(ismember(obj.recognized_UIDs,systemUID)))
                obj.system = obj.recognized_systems{ismember(obj.recognized_UIDs,systemUID)};
            else
                obj.system = systemUID;
            end
            
            % Create system directory
            root_dir = obj.createDir(root_dir, obj.system);
            
            % Create sort dir ("ByDate", etc)
            root_dir = obj.createSortDir(root_dir, header);
            
            % Create custom filter directory(ies)
            root_dir = obj.createCustomDir(root_dir, header);
        end
        
        function is_backupable = isbackupable(obj, header)
            is_backupable = 1;
        end
        
        function root_dir = createSeriesDir(obj,root_dir, header)
            % Create series directory
            series_desc = strtrim(deblank(header.series.se_desc'));
            series_name = ['Series' num2str(header.series.se_no)];
            if(length(series_desc)>0)
                series_name = [series_name '_' series_desc];
            end
            
            % Create series directory
            root_dir = obj.createDir(root_dir, series_name);
        end
        
        function pfile = backup(obj,pfile, root_dir, header, useLink, can_md5sum)
            if(obj.isbackupable(header))
                % Create root directory
                root_dir = obj.createRootDir(root_dir, header);
                
                % Move pfile to root directory
                if(iscell(root_dir))
                    num_dir = length(root_dir);
                    for i=1:num_dir
                        pfile = obj.movePfile(pfile, root_dir{i}, useLink, can_md5sum);
                    end
                else
                    pfile = obj.movePfile(pfile, root_dir, useLink, can_md5sum);
                end
            end
        end

        function pfile = movePfile(obj, pfile, pfile_new_dir, linkFile, can_md5sum)
            %Move pfile to series directory
            unique_file = 1;
            pfile_new_loc = [pfile_new_dir pfile.base];
            if(exist(pfile_new_loc))
                % Get all similar files
                similar_files = ls([pfile_new_loc '*']);
                
                % Check if the file is new (no need for duplicates!)
                same_file = 0;
                if(can_md5sum)
                    n_files = nrow(similar_files);
                    versions = zeros(1,n_files);
                    
                    for i=1:n_files
                        cur_file = [pfile.import_dir filesep() strtrim(deblank(similar_files(i,:)))];
                        same_file = sameFile(pfile_new_loc, cur_file);
                        if(same_file)
                            break; % no need to keep looking, its a duplicate!
                        end
                    end
                end
                
                % If the files are different, add a number to the file
                if(~same_file)
                    cprintf('Comments','Adding version number!\n');
                    pfile_new_loc = obj.addVersionNumber(pfile_new_dir, pfile.base, similar_files);        
                else
                    unique_file = 0;
                end
            end
            
            pfile.isduplicate = ~unique_file;
            if(unique_file);
                if(linkFile)
                    if(isfield(pfile,'data_loc'))
                        obj.makeHardlink(pfile.data_loc, pfile_new_loc);
                    else
                        error('No dataloc!');
                    end
                else
                    % Actually copy file
                    copyfile(pfile.import_file,pfile_new_loc,'f');
                    
                    pfile.data_loc = pfile_new_loc;
                    
                    % Make sure the file made it ok (md5sum check)
                    if(~sameFile(pfile.import_file,pfile_new_loc))
                        error(['md5sum error between ' pfile.import_file ' and ' pfile_new_loc]);
                    end
                    
                    % Remove tmp file
                    delete(strtrim(deblank(pfile.import_file)));
                end
            else
                % Announce that its not a unique file
                cprintf('Comments','Found duplicate file for %s, so not backing it up again.\n', pfile.base);
                
                % Delete duplicates
                delete(strtrim(deblank(pfile.import_file)));
            end
        end
        
        % Makes a link to an existing file
        function makeHardlink(obj, existingFile,link_name)
            system(['ln "' existingFile '" "' link_name '"']);
        end
        
        function newFullPath = addVersionNumber(obj, dir_name, file_name, similar_files)
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
    end
    
    methods (Abstract)
        createCustomDir(obj, root_dir, header);
    end
end
