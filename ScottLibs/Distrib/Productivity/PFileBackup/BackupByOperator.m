classdef BackupByOperator < Backupable
    properties
        byDate = BackupByDate();
        bySubject = BackupBySubject();
    end
    
    methods
        function root_dir = createSortDir(obj, root_dir, header)
            root_dir = obj.createDir(root_dir, 'ByOperator');
        end
         
        function root_dir = createCustomDir(obj, root_dir, header)
            % Add directory for operator
            root_dir = obj.createDir(root_dir, strtrim(deblank(header.exam.op')));
        
            % Add organized by date folder
            root_dir_date = obj.byDate.createSortDir(root_dir, header);
            root_dir_date = obj.byDate.createCustomDir(root_dir_date, header);
            
            % Add organized by subject directory
            root_dir_subj = obj.bySubject.createSortDir(root_dir, header);
            root_dir_subj = obj.bySubject.createCustomDir(root_dir_subj, header);
            
            root_dir = {root_dir_date,root_dir_subj};
        end
        
        function is_backupable = isbackupable(obj, header)
            is_backupable = length(strtrim(deblank(header.exam.op')))>0;
        end
    end
end