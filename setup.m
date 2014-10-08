rootDistribDir = pwd();

% Load 3p libs
disp('Loading 3rd party libs...');
path(genpath([rootDistribDir filesep() '3pLibs' filesep() 'AutoLoad']),path);

% LOAD Fesslers IRT
disp('Loading Fesslers IRT libs...');
irtdir = [rootDistribDir filesep() '3pLibs' filesep() 'ManualLoad' filesep() 'irt' filesep()];
run([irtdir 'setup.m']);
clear irtdir;

% Load my personal libs
disp('Loading Distributed Libs...');
path(genpath([rootDistribDir filesep() 'civm' ]),path);

% Compile Fesslers MEX code
disp('Compiling Fesslers Mex code...');
run([rootDistribDir filesep() '3pLibs' filesep() ...
    'ManualLoad' filesep() 'irt' filesep() 'mri' filesep()...
    'mex_build_mri.m']);

disp('Everything is stetup nicely. Enjoy...');


