classdef BackupBySubject < Backupable
    methods
         function root_dir = createSortDir(obj, root_dir, header)
            root_dir = obj.createDir(root_dir, 'BySubject');
         end
        
        function root_dir = createCustomDir(obj, root_dir, header)
            % Get subject id
            subject_id = strtrim(deblank(header.exam.patid'));
            subject_id2 = strtrim(deblank(header.exam.patname'));
            if(isempty(subject_id) && ~isempty(subject_id2))
                subject_id = subject_id2;
            end
            
            % Make sure subject id fits naming convention
            regexp_result = regexp(subject_id,'([a-zA-Z]*)(\d+)-(\d+)([a-zA-Z]*)','tokens');
            
            % Check if its a clinical dataset
            if(strcmp(obj.system,'lx-ron1') && ~isempty(regexp_result))
                subject_preface = regexp_result{1}{1};
                subject_group = regexp_result{1}{2};
                subject_id_num = regexp_result{1}{3};
                scan_identifier = regexp_result{1}{4};
                
                % Format to be 4 digits long
                subject_group = sprintf('%0.4d',str2num(subject_group));
                subject_id_num = sprintf('%0.4d',str2num(subject_id_num));

                subject_id = 'Subject_';
                if(length(subject_preface)>0)
                    subject_id = [subject_id subject_preface ];
                end
                subject_id = [subject_id subject_group '-' subject_id_num];
                
                % Add directory for subject number
                root_dir = obj.createDir(root_dir, subject_id);
                
                % If a scan identifier exists, make a directory for it
                if(~isempty(scan_identifier))
                    root_dir = obj.createDir(root_dir, ['Scan' scan_identifier]);
                end
            else
                % Add directory for subject group
                root_dir = obj.createDir(root_dir, subject_id);
            end
            
            % Create series directory
            root_dir = obj.createSeriesDir(root_dir,header);
        end
    end
end