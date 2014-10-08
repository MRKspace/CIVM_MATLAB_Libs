%CALCDCF_VORONOI   Calculated the density compensation of each trajectory
%   point based on Voronoi estimation. Note, this code will run (slightly)
%   faster in parallel (type matlabpool open to start multiple workers 
%   working in parallel). I recommend reading the following
%   article for background:
%   
%   
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2013/02/01 $
function dcf = calcDCF_Voronoi(recon_data, header)
%Add an extra point to rad_traj for DCF computation
rad_traj_ext = [calc_radial_traj_distance(header); 0];
rad_traj_ext(end)=2*rad_traj_ext(end-1)-rad_traj_ext(end-2);
skip_rad_pts = length(rad_traj_ext);

primeplus = header.rdb.rdb_hdr_user23;
tmp_traj_all = calc_archimedian_spiral_trajectories(recon_data.Nframes, primeplus, rad_traj_ext)';

%Find all unique points and the number of repetitions for
%nonunique points
[rows cols] = size(tmp_traj_all);
[sorted_traj sort_idx] = sortrows(tmp_traj_all);
first_unique = [true; any((sorted_traj(1:rows-1,:) ~= sorted_traj(2:rows,:)),2)];
unique_cumsum = cumsum(first_unique);
count_data = histc(unique_cumsum,cumsum(first_unique(first_unique)));
unique_data = sorted_traj(first_unique,:);
unique_idx = sort_idx(first_unique);
num_unique = size(unique_data,1);

% Do voronoi calculation
[v c] = voronoin(unique_data,{'Qbb '});

%use cellfun
dcf = -1*ones(num_unique,1);
parfor i = 1:length(c)
    if all(c{i}~=1) %We Dont know what to do with outermost ones...
        % Get all the vertices in the current cell, then reate convex hull 
        % and calculate area
        [K, dcf(i)] = convhulln(v(c{i},:));
    end
end

%Compensate for repeated measurements
dcf = dcf./count_data;

%Apply dcf to each point
% unsorted_dcf = zeros(size(dcf));
% unsorted_dcf(sort_idx) = dcf(unique_cumsum);
dcf(sort_idx) = dcf(unique_cumsum);

r = sqrt(tmp_traj_all(:,1).^2+tmp_traj_all(:,2).^2+tmp_traj_all(:,3).^2);
dc_mean = mean(dcf(r==min(r(:))));

%Remove data from bogus extra radial point
dcf(skip_rad_pts:skip_rad_pts:end) = [];

%Normalize DCF area to one
dcf = dcf./dc_mean;
end