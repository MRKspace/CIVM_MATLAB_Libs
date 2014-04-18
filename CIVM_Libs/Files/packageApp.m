function success = packageApp(files, packageName)
% MAke sure packageName ends in .zip
packageName = regexp(packageName,'(.*)(.zip)?$','tokens');
packageName = packageName{1}{1};

%Make a temp dir
tmp_dirname = [packageName '_tmp'];
if(exist(tmp_dirname))
    error(['Cannot create temp dir:' tmp_dirname '. Directory exists.']);
end
mkdir(tmp_dirname);

if(iscell(files))
    nfiles = length(files);
    for i=1:nfiles
        if(exist(files(i)))
            packageDependencies(files(i),tmp_dirname);
        else
            error(['File does not exist:' files(i)]);
        end
    end
elseif(isstr(files))
    if(exist(files))
        packageDependencies(files,tmp_dirname);
    end
else
    error('You must pass in a filename string or cell of strings.');
end

% Zip up directory
zip([packageName '.zip'],'*',tmp_dirname);

% Clean up
system(['rm -rf ' tmp_dirname]);

disp('Finished packaging... enjoy!');

    function packageDependencies(file_name, package_dir)
        dep = fdep(file_name);
        dep = dep.module;
        ndep = length(dep);

        for ii=1:ndep
            dep{ii}
            filename = which(dep{ii})
            
            % Put all required files in tempdir
            if(length(filename)>0)
                if(length(filename)>8)
                    if(strcmp('built-in',filename(1:8)))
                        break;
                    end
                end
                copyfile(filename, package_dir);
            else
                disp(['File (' dep{ii} ') not found using which.']);
            end
        end
    end
end