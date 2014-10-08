function [data, traj, header] = undoloopfactor(data, traj, header)
% Get relavent info from header
loop_factor = header.rdb.rdb_hdr_user10;
nframes = header.rdb.rdb_hdr_user20;
% per_nufft = header.rdb.rdb_hdr_user32;
% 
% if((per_nufft ~= 1) & (loop_factor > 1))
% 	% Warn user that loopfactor and non archimedial traj dont work
% 	h = warndlg(['If per_nufft~=1, loopfactor cant be greater than 1! ' ...
% 		'Results will be unpredictable...'],'!! Warning !!');
% 	uiwait(h);
% end

old_idx = 1:nframes;
new_idx = mod((old_idx-1)*loop_factor,nframes)+1;

data(:,old_idx) = data(:,new_idx);
traj(:,old_idx, :) = traj(:,new_idx,:);

% Update header in case you try to undo loopfactor again (it will do
% nothing)
header.rdb.rdb_hdr_user10 = 1;