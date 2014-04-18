copy_from = uigetdir('.','Select directory search for pfiles');
copy_to = uigetdir('.','Select location to copy pfiles');

% Find all radial pfiles from subjects
list = demo_findRadialSubjectPFiles(copy_from);

nlist = numel(list);
% Copy them to USB
for i=1:nlist
    [pathstr, name, ext] = fileparts(list{i});
    
    % Check if it already exists
    file_put_loc = [copy_to filesep() name ext]; 
    if(exist(file_put_loc))
        dup_put_loc_base = [file_put_loc '_dup'];
        if(~exist(dup_put_loc_base ))
            mkdir(dup_put_loc_base );
        end
        
        dup_count = 0;
        dup_put_loc = dup_put_loc_base;
        while(exist(dup_put_loc))
            dup_count = dup_count + 1; 
            dup_put_loc = [dup_put_loc_base filesep() 'dup' ...
                num2str(dup_count)];
        end
        mkdir(dup_put_loc);
        file_put_loc = dup_put_loc;
    end
    
    % Copy files
    copyfile(list{i},file_put_loc);
end