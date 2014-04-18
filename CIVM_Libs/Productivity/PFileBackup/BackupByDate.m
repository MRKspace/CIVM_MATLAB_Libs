classdef BackupByDate < Backupable
    methods
        function root_dir = createCustomDir(obj, root_dir, header)
            % Create directory with date of scan
            if(header.exam.ex_datetime == 0)
                %Create exam and series dates in YYYY_MM_DD format
                exam_timestamp = ['20' header.rdb.rdb_hdr_scan_date(8:9)' ...
                    '_' header.rdb.rdb_hdr_scan_date(1:2)' '_' ...
                    header.rdb.rdb_hdr_scan_date(4:5)'];
            else
                date_number = header.exam.ex_datetime/86400 + datenum(1970,1,1);
                exam_timestamp = datestr(date_number,'yyyy_mm_dd_HH_MM_SS');
            end
            
            % Create folder for pfile date
            root_dir = obj.createDir(root_dir, exam_timestamp);
            
            % Create series folder
            root_dir = obj.createSeriesDir(root_dir,header);
        end
        
        function root_dir = createSortDir(obj, root_dir, header)
            root_dir = obj.createDir(root_dir, 'ByDate');
        end
    end
end