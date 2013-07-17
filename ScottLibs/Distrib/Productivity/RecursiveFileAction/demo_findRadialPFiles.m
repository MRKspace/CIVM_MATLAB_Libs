function pfiles = demo_findRadialPFiles(varargin)
% If starting directory is given, us it... otherwise ask nicely for dir.
if(nargin == 0 || ~exist(varargin{1}))
    starting_dir = uigetdir();
else
    starting_dir = varargin{1};
end
disp(['Finding all pfiles in ' starting_dir]);

pfiles = {};
[pfiles] = RecursiveFileAction(starting_dir,@isRadialPfile,@addToList,0,pfiles);
disp(['Found ' num2str(length(pfiles)) ' Radial Pfiles.']);

% Check if file is a radial Pfile
    function t_f = isRadialPfile(file_)
        [pathstr, name, ext] = fileparts(file_);
        
        % First just check if its a pfile
        t_f = false;
        if(length(name)>0 & length(ext)>0 & ...
                strcmp('P',name(1)) & strcmp('.7',ext))
            % If its a pfile, read header and see if scan was a radial
            % sequence
            psdname = getPfilePSDName(file_);
            
            t_f = ~isempty(strfind(psdname,'3dradial'));
        end
    end

% if file is a radial pfile, add it to list of pfiles!
    function currentList = addToList(file_, currentList)
        currentList{end+1} =  file_;
    end

% Returns the pulse sequence name used in a pfile
    function psdname = getPfilePSDName(pfilename)
        % Parameters that almost never change.
        hdr_off    = 0;         % Typically there is no offset to the header
        byte_order = 'ieee-le'; % Assume little endian format
        precision='int16';      % Can we read this from header? CSI extended mode uses int32
        revision = 11;
        
        %Read header and unique series identifier
        header = ge_read_header(pfilename, revision, hdr_off, byte_order);
        psdname = deblank(header.image.psdname');
    end
end