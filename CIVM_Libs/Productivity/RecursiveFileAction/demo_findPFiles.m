function pfiles = demo_findPFiles(varargin)
% If starting directory is given, us it... otherwise ask nicely for dir.
if(nargin == 0 || ~exist(varargin{1}))
    starting_dir = uigetdir();
else
    starting_dir = varargin{1};
end

pfiles = {};
[pfiles] = RecursiveFileAction(starting_dir,@isPfile,@addToList,0,pfiles);
disp(['Found ' num2str(length(pfiles)) ' Pfiles.']);

% Check if file is a pfile
    function t_f = isPfile(file_)
        [pathstr, name, ext] = fileparts(file_);
        t_f = strcmp('P',name(1)) & strcmp('.7',ext);
    end

% if file is a pfile, add it to list of pfiles!
    function currentList = addToList(file_, currentList)
        currentList{end+1} =  file_;
    end
end