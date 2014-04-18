function pfiles = demo_findRadialSubjectPFiles(varargin)
% If starting directory is given, us it... otherwise ask nicely for dir.
if(nargin == 0 || ~exist(varargin{1}))
    starting_dir = uigetdir();
else
    starting_dir = varargin{1};
end
disp(['Finding all radial pfiles with a subject in ' starting_dir]);

% Parameters that almost never change.
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
precision='int16';      % Can we read this from header? CSI extended mode uses int32
revision = 15;

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
            
             %Read header and unique series identifier
             header = ge_read_header(file_, revision, hdr_off, byte_order);
        
            % If its a pfile, read header and see if scan was a radial
            % sequence
            psdname = getPfilePSDName(header);
            
            % Read header and see if it has a subject
            %Should be the same
            pat_id = deblank(header.exam.patid');
            pat_id2 = deblank(header.exam.patname');
            if(isempty(pat_id) && ~isempty(pat_id2))
                pat_id = pat_id2;
            end
            
            % Make sure patient id fits naming convention
            regexp_result =  regexp(pat_id,'(\d+-\d+)([a-zA-Z]*)','tokens');

            t_f = ((~isempty(strfind(psdname,'3dradial'))&&~isempty(regexp_result)));
        end
    end

% if file is a radial pfile, add it to list of pfiles!
    function currentList = addToList(file_, currentList)
        currentList{end+1} =  file_;
    end

% Returns the pulse sequence name used in a pfile
    function psdname = getPfilePSDName(header)
       psdname = deblank(header.image.psdname');
    end
end