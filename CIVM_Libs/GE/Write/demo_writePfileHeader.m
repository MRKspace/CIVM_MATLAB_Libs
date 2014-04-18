% Ask nicely for pfile
pfile_name = filepath([], 'Select P-File');
[path file ext] = fileparts(pfile_name);

% Ask nicely for location to put header data
[write_file, write_path] = uiputfile('*.*', 'Where do you want to save header data?');
if(isempty(regexp(write_file,'.*.csv$')))
    write_file = [write_file '.csv'];
end;
csv_filename = [write_path filesep() write_file];

% Read header, write CSV file, and display it
writeHeaderCSV(csv_filename, pfile_name, 1);