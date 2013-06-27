function [params] = RecursiveFileAction(start_dir,performActionFcn,actionFcn,num_found,params)

% Get a list of everything in the directory
dir_elements = ls(start_dir);
if(size(dir_elements,1)<3)
    return;
end
dir_elements = dir_elements(3:end,:);

% If directory isnt empty, loop through its contents
if(size(dir_elements,1)>0)
    numElements = size(dir_elements, 1);
    for i=1:numElements
        cur_element = deblank([start_dir filesep() dir_elements(i,:)]);
        
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
