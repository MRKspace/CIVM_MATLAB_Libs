clc; clear all; close all;
tic;

% Turn plotting on/off
plot_stuff = 1;

% Read in a pfile
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
undo_loopfactor = 0;    % No need to undo loopfactor, they are in order the same way the trajectories are
precision='int16';      % Can we read this from header? CSI extended mode uses int32
% [file, path] = uigetfile('*.*', 'Select Pfile');
% pfile_name = strcat(path, file)
% pfile_name = 'C:\Users\ScottHaileRobertson\Documents\MATLAB_libs\Datasets\Pfiles\P16384_lung.p';
% header = ge_read_header(pfile_name, hdr_off, byte_order);
% fid_data = FID_Data(pfile_name, byte_order, precision, header);

% %Add an extra point to rad_traj for DCF computation
% [rad_traj gradients, ideal_traj] = calc_radial_traj_distance(header);
% extra_dist = rad_traj(end) - rad_traj(end-1);
% rad_traj(end+1)=rad_traj(end)+extra_dist;
% primeplus = header.rdb.rdb_hdr_user23;
% fid_data.Traj = calc_archimedian_spiral_trajectories(fid_data.Nframes, primeplus, rad_traj);
% 
% primeplus = header.rdb.rdb_hdr_user23;
% x = fid_data.Traj';

% Generate archimedian spiral trajectories
rad_traj = linspace(0,0.5,3);
rad_traj = rad_traj';
primeplus = 101;
x = calc_archimedian_spiral_trajectories(150, primeplus, rad_traj)';

% % Create sphere where points can exist
% [x_sphere, y_sphere, z_sphere] = sphere(40);
% x_sphere = 0.5 * x_sphere;
% y_sphere = 0.5 * y_sphere;
% z_sphere = 0.5 * z_sphere;
% bound_x = [x_sphere(:) y_sphere(:) z_sphere(:)]*5;

if(plot_stuff )
    figure();
    plot3(x(:,1),x(:,2),x(:,3),'.r', 'MarkerSize',20,'LineWidth',1);
    hold on;
    hidden off;
    % % h = mesh(x_sphere, y_sphere, z_sphere,'EdgeColor','black');
    % % alpha(h, 0.25);
end

% Set boundary of sphere
% x = [x; bound_x];
x = unique(x,'rows');
r_x = sqrt(x(:,1).^2 + x(:,2).^2 + x(:,3).^2);

% Do voronoi calculation
[v c] = voronoin(x,{'Qbb'});

% Force to fit in sphere
% r = sqrt(v(:,1).^2 + v(:,2).^2 + v(:,3).^2);
% outside = r>0.5;
% v(outside,1) = v(outside,1)./(2*r(outside));
% v(outside,2) = v(outside,2)./(2*r(outside));
% v(outside,3) = v(outside,3)./(2*r(outside));

% Loop through each Voronoi cell and compute the volume
cols = ['y', 'm', 'c', 'r', 'g', 'b', 'k', 'w'];
dcf = zeros(size(r_x));
for i = 1:length(c)
    if all(c{i}~=1) %We Dont know what to do with outermost ones...
        %Randomly pick a color for the cell
        col = cols(randi([1 8]));
        
        % Get all the vertices in the current cell
        X = v(c{i},:);
        
        % Create convex hull
        [K, dcf(i)] = convhulln(X);
        
        %         n = isonormals(X(:,1),X(:,2),X(:,3),V,vertices)
        
        if(plot_stuff)
            %Show the cell as a semi-transparent patch;
            h = patch('faces',K,'vertices',X,'FaceColor',col,...
                'EdgeColor','none','FaceLighting','phong',...
                'DiffuseStrength',1,'AmbientStrength',.2,...
                'SpecularStrength',0.7);
%             h = patch('faces',K,'vertices',X,'FaceColor','none',...
%                 'EdgeColor',col,'FaceLighting','phong',...
%                 'DiffuseStrength',1,'AmbientStrength',.2,...
%                 'SpecularStrength',0.7);
            alpha(h,0.3);
        end
    end
end

if(plot_stuff)
    camlight; camlight(-80,-10); lighting phong;
    hold off;
end

%Keep track of time
total_time = toc

% %Normalize density and dcf plots
% in_sphere = r_x < 2;
% r_x = r_x(in_sphere);
% dcf = dcf(in_sphere);
% dens = 1./dcf;
% dens = 100*dens/(max(dens(:)));
% dcf = 100*dcf/max(dcf(:));
% 
% figure();
% plot(100*r_x, dens,'.b');
% hold on;
% plot(100*r_x, dcf,'.r');
% plot(100*r_x, r_x.*r_x,'-g');
% hold off;
% xlabel('Distance allong a radial ray (%)');
% ylabel('Relative Scale (%)');
% legend('Relative density of information','Relative density compensation','Ramp filter (1/r)');
