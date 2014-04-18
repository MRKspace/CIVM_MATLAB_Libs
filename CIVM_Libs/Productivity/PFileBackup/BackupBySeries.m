classdef BackupBySeries < Backupable
    properties
        byDate = BackupByDate();
        bySubject = BackupBySubject();
    end
    
    methods
        function root_dir = createSortDir(obj, root_dir, header)
            root_dir = obj.createDir(root_dir, 'BySeries');
        end
        
        function root_dir = createCustomDir(obj, root_dir, header)
            % Create series directory
            series_name = strtrim(deblank(header.series.se_desc'));
            
            % Create series directory
            root_dir = obj.createDir(root_dir, series_name);
            
            % Add organized by date folder
            root_dir_date = obj.byDate.createSortDir(root_dir, header);
            root_dir_date = obj.byDate.createCustomDir(root_dir_date, header);
            
            % Add organized by subject directory
            root_dir_subj = obj.bySubject.createSortDir(root_dir, header);
            root_dir_subj = obj.bySubject.createCustomDir(root_dir_subj, header);
            
            root_dir = {root_dir_date,root_dir_subj};
        end
    end
end