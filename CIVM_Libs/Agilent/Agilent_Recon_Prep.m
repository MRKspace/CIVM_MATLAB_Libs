function [data, traj, header] = Agilent_Recon_Prep(fid_filename, procpar_filename)
% Read Agilent header
procpar = readprocpar(procpar_filename);
[npoints,nblocks,ntraces,bitdepth] = load_fid_hdr(fid_filename);
npoints = npoints/2; % Due to complex data
pan_ang = procpar.nv;
pan_rot = procpar.nv2;

% Read in data
data = load_fid(fid_filename,nblocks,ntraces,2*npoints,bitdepth,1,[npoints pan_ang pan_rot procpar.nblocks]);
nblocks = procpar.nblocks;

% Calculate trajectories based on pulse sequence
% psdname = procpar.psd;
% switch(psdname)
%     case '3dradial'
        %% Handle gradient delays, etc
        samp_time = 1/(2*procpar.sw); % Takes twice as long since we need real, imaginary
        t = 0:samp_time:samp_time*((npoints)-1);
        dc_time = 2*samp_time;
        plateau_time = 100*samp_time;
        ramp_time = procpar.at;
        
        % Create Gradients and radial kspace location
        grad = (t-dc_time).*(t>dc_time).*(t<(dc_time+ramp_time)) + ...
            (ramp_time).*(t>=(dc_time+ramp_time));
        r = 0.5*(t-dc_time).^2.*(t>dc_time).*(t<(dc_time+ramp_time)) + ...
            (ramp_time).*(0.5*(ramp_time)+(t-(dc_time+ramp_time))).*(t>=(dc_time+ramp_time));
        r = 0.5*r/max(abs(r(:)));
        
        % %Plot gradients
        % figure();
        % subplot(1,3,1);plot(t,grad,'r');xlabel('time');ylabel('Gradient');
        % subplot(1,3,2);plot(t,r,'-b');xlabel('time');ylabel('kspace location');
        
        % Create radial sampling
        r = repmat(r',[1 pan_ang pan_rot]);
        phi = linspace(0, 2*pi, pan_ang+1);
        phi = phi(1:(end-1));
        phi = repmat(phi,[npoints 1 pan_rot]);
        
        theta = linspace(0, pi, pan_rot+1);
        theta = theta(1:(end-1));
        theta = repmat(permute(theta,[1 3 2]),[npoints pan_ang 1]);

        kx = r.*sin(phi).*cos(theta);
        ky = r.*sin(phi).*sin(theta);
        kz = r.*cos(phi);
        
        % Prepare output
        header.MatrixSize = [npoints npoints npoints];
        traj = 2*pi*[kx(:)'; ky(:)'; kz(:)']';
%     otherwise
%         error(['Pulse sequence not recognized. Cannot generate trajectories. (' psdname ')']);
% end

end