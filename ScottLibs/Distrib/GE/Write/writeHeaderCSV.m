%WRITEHEADERCSV   Writes a header structure to CSV format
%
%   writeHeaderCSV(header_filename, header, open_after)
%
%   header_filename - The name of the CSV file to be saved
%   header          - The header structure to be written
%   open_after      - If true (1), the file will be opened after written
% 
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: Dec 12, 2012 $
function writeHeaderCSV(header_filename, header, open_after)

% Create CSV file
fid=fopen(header_filename, 'wt');

% Write out the structure fields
writeStructFields(header,fid,0);

% Close CSV file
fclose(fid);

if(open_after)
    % Display the file in excell
    if isunix
        system(['open ' header_filename]);
    elseif ispc
        system(['start ' header_filename]);
    end
end
end %function

function writeStructFields(thisStruct,fid, numIndents)
% Get the field names
structFields = fieldnames(thisStruct);

% Get the total number of fields
numFields = length(structFields);

% Print out the fields as appropriate
for i=1:numFields
    % Start new line, indent properly
    writeIndention(fid, numIndents);
    
    % Get field name
    field_name = structFields{i};
    
    % Write field name to file
    fprintf(fid,[field_name ',']);
    
    % Get field value
    field_val = getField(thisStruct,field_name);
    
    % Handle various things the value could be
    if(isstruct(field_val))
        writeStructFields(field_val,fid, numIndents+1);
    elseif(isnumeric(field_val))
        fprintf(fid,'%s',num2str(field_val));
    elseif(ischar(field_val))
        fprintf(fid,'%s',field_val);
    else
        error(['Field value for ' field_name ' not supported.']);           
    end
    
end
end %function

function writeIndention(fid, numIndents)
% Create new line
fprintf(fid,'\n');

% Add proper indention
for i = 1:numIndents
    fprintf(fid,',');
end
end %function
