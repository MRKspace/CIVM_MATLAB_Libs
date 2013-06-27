%RECON_Data   A class to hold reconstruction data from an MRI scan. This is
%an object to minimize memory copying between functions.
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/07/19 $
classdef Recon_Data
    properties
        Data            %Raw sampled FID data (stored as complex data)
        Traj            %K space trajectory locations
        DCF             %Density compensation
        
        Nframes         %Number of frames in scan
        Npts            %Number of points per frame
    end
    
    methods
        function this = readPfileData(this,pfile_name,byte_order,precision,header)
            % Store important info from header
            this.Npts = header.rdb.rdb_hdr_frame_size;%view points
            this.Nframes  = header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;
            
            % Read the image data
            fid = fopen(pfile_name, 'r', byte_order);
            fseek(fid, header.rdb.rdb_hdr_off_data, 'bof');
            this.Data = fread(fid,inf,precision);
            
            % Data is complex (real and imaginery parts alternate)
            this.Data = complex(this.Data(1:2:end),this.Data(2:2:end));
            
            % Separate baselines from raw data
            this.Nframes  = length(this.Data(:))/this.Npts;
            this.Data = reshape(this.Data,this.Npts,this.Nframes);% Reshape into matrix
        end
        
        function this = removeBaselines(this,header)
            skip_frames = header.rdb.rdb_hdr_da_yres; %Changed to improve skip frames (was rdb_hdr_nframes)
            this.Data(:, 1:skip_frames:this.Nframes) = []; % Remove baselines (junk views)
            this.Nframes  = length(this.Data(:))/this.Npts;
        end
        
        function this = undo_loopfactor(this, header)
            loop_Factor = header.rdb.rdb_hdr_user10;
            old_idx = 1:this.Nframes-1;
            new_idx = mod((old_idx-1)*loop_Factor,this.Nframes-1)+1;
            this.Data(:,new_idx) = this.Data(:,old_idx);
            clear old_idx new_idx;
        end
    end
end