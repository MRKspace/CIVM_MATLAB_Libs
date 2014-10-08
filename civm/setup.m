% Restore default path
% restoredefaultpath();

rootDistribDir = pwd();

% Load 3p libs
% disp('Loading 3rd party libs...');
% path(genpath([rootDistribDir filesep() '3pLibs' filesep() 'AutoLoad']),path);

% Load my personal libs
disp('Loading Distributed Libs...');
path(genpath([rootDistribDir filesep() 'civm']),path);

disp('Everything is stetup nicely. Enjoy...');