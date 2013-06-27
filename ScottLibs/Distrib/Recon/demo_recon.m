% Start with a clean slate
clc; clear all; close all;

% options.headerfilename = filepath('C:\Users\ScottHaileRobertson\Desktop\mions\MattPromisingPfiles\Helium\P36352.7_preProton');
options.headerfilename = filepath();
% options.headerfilename = filepath();
options.datafilename = '';
options.overgridfactor = 2;
options.nNeighbors = 3;
options.scale = sqrt(3);
options.dcf_iter = 5
   
tic;
[recon_vol, header, reconObj] = Recon_Noncartesian(options);
initial_recon_time = toc

%Show output
figure();
imslice(abs(recon_vol),'Reconstruction');

% % Now add the reconObject and run again... this will show how much time it
% % takes to create the reconstruction object and calculate density
% % compensation. If you are reconstructing multiple similar reconstructions,
% % its much more efficient to run the recon once, save the reconObj, then
% % run it for future reconstructions using the reconObj.
% options.reconObj = reconObj;
% 
% tic;
% [recon_vol, header, reconObj] = Recon_Noncartesian(options);
% second_recon_time = toc


