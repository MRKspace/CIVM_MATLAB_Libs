% Uses an md5sum to check if two files are the same
function same_file = sameFile(file1, file2)
    % Get md5sum of file1
    file1 = strtrim(file1);
    [error1 md5sum1] = system(['md5sum ''' file1 '''']);
    md5sum1 = regexp(md5sum1,'\s+','split');
    md5sum1 = md5sum1{1};
    
    % Check for md5sum error
    if(error1)
        error(['ERROR in md5sum of file ' file1 ' message: ' md5sum1]);
    end
    
    % Get md5sum of file2
    file2 = strtrim(file2);
    [error2 md5sum2] = system(['md5sum ''' file2 '''']);
    md5sum2 = regexp(md5sum2,'\s+','split');
    md5sum2 = md5sum2{1};
    
    % Check for md5sum error
    if(error2)
        error(['ERROR in md5sum of file ' file2 ' message: ' md5sum2]);
    end
    
    % Check if they are the same
    same_file = strcmp(md5sum1,md5sum2);
end