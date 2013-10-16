% Uses an md5sum to check if two files are the same
function same_file = sameFile(file1, file2)
    % Get md5sum of file1
    [status md5sum1] = system(['md5sum ' file1]);
    md5sum1 = regexp(md5sum1,'(.*[a-zA-z0-9]+) .*','tokens');
    md5sum1 = md5sum1{1};
    
    % Get md5sum of file2
    [status md5sum2] = system(['md5sum ' file2]);
    md5sum2 = regexp(md5sum2,'(.*[a-zA-z0-9]+) .*','tokens');
    md5sum2 = md5sum2{1};
    
    % Check if they are the same
    same_file = strcmp(md5sum1,md5sum2);
end