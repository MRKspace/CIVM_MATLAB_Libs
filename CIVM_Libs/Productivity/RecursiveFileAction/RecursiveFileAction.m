function [params] = RecursiveFileAction(start_dir,performActionFcn,actionFcn,num_found,params)

% Get a list of everything in the directory
dir_elements = dir(start_dir);
if(length(dir_elements)<3)
    return;
end
dir_elements = dir_elements(3:end); %remove '.' and '..'

% If directory isnt empty, loop through its contents
if(length(dir_elements)>0)
    numElements = length(dir_elements);
    for i=1:numElements
        cur_element = deblank([start_dir filesep() dir_elements(i).name]);
        
        if(isdir(cur_element))
            % Recurse through directories
            [params] = RecursiveFileAction(cur_element,performActionFcn,actionFcn,num_found,params);
        else
            % Check if we should perform action on element
            if(performActionFcn(cur_element))
                % Perform action
                params = actionFcn(cur_element,params);
            end
        end
    end
end
end
