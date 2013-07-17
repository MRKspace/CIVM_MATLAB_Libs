% Start with a clean slate
clc; clear all; close all;

options.datafilename = '';
options.overgridfactor = 2;
options.nNeighbors = 3;
options.scale = 2;
options.dcf_iter = 25
   
% Get a list of all the files to be reconstructed
files_to_recon = demo_findRadialPFiles();

% Reconstruct first file
tic;
options.headerfilename = filepath(files_to_recon{1});
[recon_vol, header, reconObj] = Recon_Noncartesian(options);
disp(['Reconstructed file 1 in ' num2str(toc) ' seconds.']);

% Save the reconstruction of the first file
descr = ['Pfile:' files_to_recon{1} ...
    ', overgrid:' num2str(options.overgridfactor) ...
    ', nNeighbots:' num2str(options.nNeighbors) ...
    ', scale:' num2str(scale) ...
    ', dcf_iter:' num2str(options.dcf_iter)];
nii = make_nii(abs(recon_vol), [1 1 1], [1 1 1], 32, )
save_nii(make_nii(abs(recon_vol)),[files_to_recon{1} '_recon_mag.nii'],16);

% Now add the reconObject and run the recon for the other files - this 
% additional reconstructions will be faster because we don't have to 
% create the reconstruction object and calculate density compensation. 
% If you are reconstructing multiple similar reconstructions,
% its much more efficient to run the recon once, save the reconObj, then
% run it for future reconstructions using the reconObj.
options.reconObj = reconObj;

% Loop through additional reconstructions
numFilesToRecon = length(files_to_recon);
for i=2:numFilesToRecon
    % get next file ready
    options.headerfilename = filepath(files_to_recon{1});

    % Reconstruct next file
    [recon_vol, header, reconObj] = Recon_Noncartesian(options);
    disp(['Reconstructed file ' num2str(i) ' in ' num2str(toc) ' seconds.']);
    
    % Save the reconstruction of the first file
    save_nii(make_nii(abs(recon_vol)),[files_to_recon{1} '_recon_mag.nii'],16);
end

