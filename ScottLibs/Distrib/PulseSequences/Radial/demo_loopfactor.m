clc; clear all; close all;
% loop_factors = [1229   1453 1523 1301 1423 1549 1427 1327 1291 1451];
loop_factors = [1301 ];
nloopFactors = length(loop_factors(:))

for i=1:nloopFactors
    i
    loop_factor = loop_factors(i);
    
    % Create demo trajectories;
    nframes = 3999;
    primeplus = 101;
    rad = [0 0.5]';
    traj = calc_archimedian_spiral_trajectories(nframes, primeplus, rad);
    traj = reshape(traj',[2 nframes 3]);
    
    
    old_idx = 1:nframes;
    new_idx = mod((old_idx-1)*loop_factor,nframes)+1;
    traj2(:,new_idx,:) = traj(:,old_idx,:);
    
    % Create line of sampling
    npts = nframes*10;
    cview=floor(nframes/2)+1;     %Center frame
    kspace_traj=zeros(3,length(rad)*npts);
    
    is = linspace(0,nframes-1,npts); %In Gary's code, i=acview_start
    fs = 1-(is/cview); %In Gary's code f=fThing
    angs = primeplus.*is.*(pi/180); %Angle in radians
    ds = sqrt(1-(fs.^2));
    x_coords = ds.*cos(angs);
    y_coords = ds.*sin(angs);
    z_coords = sqrt(1-((x_coords.^2)+(y_coords.^2)));
    
    %Handle negatives
    z_coords = z_coords.*((2*(is<=cview))-1);
    
    %normalize
    ivec_lengths = 1./sqrt((x_coords.^2) + (y_coords.^2) + (z_coords.^2));
    xs = x_coords.*ivec_lengths;
    ys = y_coords.*ivec_lengths;
    zs = z_coords.*ivec_lengths;
    
    thetas = acos(zs);
    phis = atan2(y_coords,x_coords);
    
    kx = rad*(sin(thetas).*cos(phis)); %x-coordinates of rays
    ky = rad*(sin(thetas).*sin(phis)); %y-coordinates of rays
    kz = rad*(cos(thetas)); %z-coordinates of rays
    
    kspace_traj(1,:) = kx(:);
    kspace_traj(2,:) = ky(:);
    kspace_traj(3,:) = kz(:);
    kspace_traj = kspace_traj';
    kspace_traj = reshape(kspace_traj, [2 npts 3]);
    
    % Show all trajectories
    figure(1);
    plot3(traj(2,:,1),traj(2,:,2),traj(2,:,3),'.r');
    patchline(traj(:,:,1),traj(:,:,2),traj(:,:,3),...
        'linestyle','-', 'edgecolor','g','edgealpha',0.4);
    axis square;
    title('Trajectories');
    
    % Make loopfactor movie
    viewsPerFrame = 250;
    viewStepSize = 10;
    totalFrames = floor(nframes/viewsPerFrame);
    
    movieName = ['loopfactor' num2str(loop_factor)];
    vidObj = VideoWriter(movieName);
    vidObj.FrameRate = 5;
    vidObj.Quality = 100;
    open(vidObj);
    
    fig = figure(1);
    for j=0:viewStepSize:(nframes - viewsPerFrame - 1)
        idx = j+[1:viewsPerFrame];
        plot3(traj2(2,idx,1),traj2(2,idx,2),traj2(2,idx,3),'.r');
        patchline(traj2(:,idx,1),traj2(:,idx,2),traj2(:,idx,3),...
            'linestyle','-', 'edgecolor','r','edgealpha',0.4, 'linewidth', 1);
        patchline(kspace_traj(2,:,1),kspace_traj(2,:,2),kspace_traj(2,:,3),...
            'linestyle','-', 'edgecolor','b','edgealpha',0.4, 'linewidth', 1);
        axis([-0.5 0.5 -0.5 0.5 -0.5 0.5]);
        axis square;
        title(['Loopfactor=' num2str(loop_factor) ', Views ' num2str(min(idx)) '-' num2str(max(idx))]);
        
        % Write each frame to the file.
        writeVideo(vidObj,getframe(fig));
    end
    close(vidObj);
end