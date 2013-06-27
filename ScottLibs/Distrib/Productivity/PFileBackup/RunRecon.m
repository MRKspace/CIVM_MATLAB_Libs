load('RadialPfiles');

%Do all prep work on first file
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
undo_loopfactor = 0;    % No need to undo loopfactor, they are in order the same way the trajectories are
precision = 'int16';      % Can we read this from header? CSI extended mode uses int32

% Typical Recon Params
kernel_width   = 1;
overgridfactor = 2;
scale = 1.6;
itter = 60;

numPfiles = length(radial_list);
for i= 2:numPfiles
    disp('****************************');
    disp('****************************');
    disp([num2str(i) 'RECONSTRUCTING: ' radial_list{i}]);
    disp('****************************');
    disp('****************************');
    % Read header
    pfile_name = radial_list{i};
    header = ge_read_header(pfile_name, hdr_off, byte_order);
    
    % Read pfile data
    recon_data = Recon_Data();
    recon_data = recon_data.readPfileData(pfile_name,byte_order, precision,header);
    recon_data = recon_data.removeBaselines(header);
    recon_data.Data = recon_data.Data(:);
    
    % Get prep data
    lookup_name = [num2str(recon_data.Nframes) '_' ...
        num2str(header.rdb.rdb_hdr_user23) '_' ...
        num2str(header.rdb.rdb_hdr_user12) '_' ...
        num2str(header.rdb.rdb_hdr_user1)  '_' ...
        num2str(header.rdb.rdb_hdr_frame_size) '_' ...
        num2str(header.rdb.rdb_hdr_user22) '_' ...
        num2str(overgridfactor)  '_' ...
        num2str(scale)  '_' ...
        num2str(kernel_width)  '_' ...
        num2str(itter) ...
        '.mat'];
    
    nufftObj = {};
    if(~exist(lookup_name))
        disp(['Creating NUFFT Object for ' lookup_name]);
        rad_traj  = calc_radial_traj_distance(header);
        traj = 2*pi*calc_archimedian_spiral_trajectories(...
            recon_data.Nframes, header.rdb.rdb_hdr_user23, ...
            rad_traj)';
        num_points   = header.rdb.rdb_hdr_frame_size;
        output_dims  = uint32(round(scale*[num_points num_points num_points]));
        
        %Prepare NUFFT object
        N = round(scale*[num_points num_points num_points]);
        J = ceil(overgridfactor*[kernel_width kernel_width kernel_width]);
        K = N*overgridfactor;
        nufft_st = nufft_init(traj,N,J,K,N/2,'minmax:kb');
        
        %Prepare GNUFFT object
        nufftObj.G = Gnufft(nufft_st);
        
        % Calculate DCF
        w = ones(size(recon_data.Data));
        P = nufftObj.G.arg.st.p;
        
        for ii=1:itter
            tmp = P * (P' * w);
            w = w ./ real(tmp);
        end
        nufftObj.wt.pipe = w;
        gmri()
        save(lookup_name, 'nufftObj');
    else
        disp(['Using ' lookup_name]);
        load(lookup_name);
    end
    
    % Reconstruct
    mask =  true(nufftObj.G.st.Nd);
    recon_vol = embed(nufftObj.G' * (nufftObj.wt.pipe .* recon_data.Data), mask);
    
    % Save images
%     saveVolumeAsImageStack(abs(recon_vol), 'test', 'tiff');
    
    imslice(abs(recon_vol));
    
    test = 1;
    delete(nufftObj)
    clear nufftObj;
end