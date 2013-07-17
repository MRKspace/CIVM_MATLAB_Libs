function [recon_vol, varargout] = Recon_Noncartesian(varargin)
if(nargin >0)
    options = varargin{1};
end

% Make a new options struct if it does not exist
if(~isstruct(options))
    error('Options must be provided as a structure');
end
if(isempty(fieldnames(options)))
    options = struct();
end

% Check for provided files
if(~isfield(options,'datafilename'))
    options.datafilename = filepath([],'Select Header file');
    options.headerfilename = filepath([],'Select Data file');
end

% Assume no headerfile is not needed if not given.
if(~isfield(options, 'headerfilename'))
    options.headerfilename = '';
end

% Read in the file and prepare for generic reconstruction
% Check if its a GE Pfile or RP file
% Find our which revision of scanner it is (only works with rdb version 11 and 15 now...)
[revision, logo] = ge_read_rdb_rev_and_logo(options.headerfilename);
if(~isempty(strfind(logo,'MR')))
    disp('Detected GE Pfile. Prepping for reconstruction...');
    [data, traj, weights, header] = GE_Recon_Prep(options.headerfilename, ...
        floor(revision), options.datafilename);
    
%     % Temporally chop the data
%     start_frame = 0+1;
%     nframes_ = 50;
%     npts = header.ge_header.rdb.rdb_hdr_frame_size;%view points
%     nframes  = header.ge_header.rdb.rdb_hdr_user20; %will change to header.rdb.rdb_hdr_user5 once baselines are removed;
%     
%     traj_ = reshape(traj,[npts nframes 3]);
%     traj_ = traj_(:,start_frame:(start_frame+nframes_ - 1),:);
% 
%     % Show sampling
%     figure();
%     plot3(traj_(npts,:,1),traj_(npts,:,2),traj_(npts,:,3),'.b');
%     hold on;
%     plot3(traj_(npts,:,1),traj_(npts,:,2),traj_(npts,:,3),':r');
%     hold off;
%     axis([-0.6 0.6 -0.6 0.6 -0.6 0.6]);
    
    % If two outputs are requested, the second is the header
    if(nargout > 1)
        varargout{1} = header.ge_header;
    end
elseif(true)
    disp('Detected Agilent FID file. Prepping for reconstruction...');
    options.datafilename = [filename filesep() 'fid'];
    options.headerfilename = [filename filesep() 'procpar'];
    [data, traj, header] = Agilent_Recon_Prep(options.datafilename,...
        options.headerfilename);
else
    error(['File format (' options.datafilename ') not understood.']);
end

if(isfield(options, 'traj'))
    traj = options.traj;
end

if(isfield(options, 'data'))
    data = options.data;
end

% If recon object is provided, make sure it matches the input data
% reasonably well.
if(isfield(options, 'reconObj'))
    N = floor(options.scale*header.MatrixSize)
    2*round((N-1)/2)+1; % Make sure N is even
    J = [options.nNeighbors options.nNeighbors options.nNeighbors];
    K = ceil(N*options.overgridfactor);
    
    if(N ~= options.reconObj.G.arg.Gnufft.arg.st.Nd)
        error('Output image size of reconObj does not match data.');
    elseif(J ~= options.reconObj.G.arg.Gnufft.arg.st.Jd)
        error('Number of neighbors of options does not match reconObj');
    elseif(K ~= options.reconObj.G.arg.Gnufft.arg.st.Kd)
        error('Overgrid matrix dims of reconObj do not match data');
    elseif(size(traj) ~= size(options.reconObj.G.arg.Gnufft.arg.st.om))
        error('Different number of trajectory values in data and reconObj');
    elseif(traj ~= options.reconObj.G.arg.Gnufft.arg.st.om)
        error('Trajectory values are different between data and reconObj');
    end
else
    %Check for optional gridding arguments and supply defaults for missing
    %values.
    if(~isfield(options, 'overgridfactor'))
        options.overgridfactor = 2;
    end
    if(~isfield(options, 'nNeighbors'))
        options.nNeighbors = 3;
    end
    if(~isfield(options, 'scale'))
        options.scale = 1;
    end
    if(~isfield(options, 'dcf_iter'))
        options.dcf_iter = 5;
    end
    
    %% reconstruct
    inv_scale = 1/options.scale;
    N = floor(options.scale*header.MatrixSize);
    2*round((N-1)/2)+1; % Make sure N is even
    J = [options.nNeighbors options.nNeighbors options.nNeighbors];
    K = ceil(N*options.overgridfactor);
    
    %Prepare Sparse Recon object (NUFFT or exact fft)
    %         nufft_a = nufft_init(2*pi*inv_scale*traj,N,J,K,N/2,'minmax:kb');
    
    % optimize min-max error accross volume
    %     reconObj.G = Gnufft(nufft_a);
    %     reconObj.G = Gdsft(traj,N,'n_shift',N/2,'useloop',1,'use_mex',1); %'class','exact'
    
    %     reconObj.G = Gdsft(traj,N,'n_shift',N/2,'useloop',1,'use_mex',1); %'class','exact';
    reconObj.G = Gmri(inv_scale*traj, true(N), 'fov', N, 'nufft_args', {N,J,K,N/2,'minmax:kb'});
    clear N K J traj nuft_a;
    
    %% Calculate Sample Density Corrections
    disp('Itteratively calculating density compensation coefficients...');
    reconObj.wt.pipe = ones(size(reconObj.G.kspace,1),1);
%     pipe2 = ones(size(reconObj.G.kspace,1),1);
    %     reconObj.wt.pipe = ones(reconObj.G.odim,1);
    reconObj.wt.max_itter = options.dcf_iter;
    
    % From here on scales with overgrid
    for iter = 1:options.dcf_iter
        disp(['   Iteration:' num2str(iter)]);
        % p-> overgridded G->normal image dims
        reconObj.wt.pipe = abs(reconObj.wt.pipe ./ ...
            ((reconObj.G.arg.Gnufft.arg.st.p * ...
            (reconObj.G.arg.Gnufft.arg.st.p'*(reconObj.wt.pipe)))));
        
%                 pipe2 = abs((pipe2) ./ ...
%                     (reconObj.G.arg.Gnufft.arg.st.p * (reconObj.G.arg.Gnufft.arg.st.p'*(pipe2.*weights))));
%         
%                 figure(1);
%                 pipe1_ = reshape(reconObj.wt.pipe , [header.ge_header.rdb.rdb_hdr_frame_size ...
%                     1001]);
%                 pipe2_ = reshape(pipe2 , [header.ge_header.rdb.rdb_hdr_frame_size ...
%                     1001]);
%                 surf(pipe1_./pipe2_);
%                 shading interp;
%                 colormap(jet);
%                 a = 1;
    end
    
    
    
    %     %For exact recon
    %     reconObj.G = Gmri(inv_scale*reconObj.G.arg.kspace, ...
    %         true(reconObj.G.arg.nufft_args{1}), 'exact', 1, 'n_shift', ...
    %         reconObj.G.arg.nufft_args{1}/2);
    %     for iter = 1:options.dcf_iter
    %         disp(['   Iteration:' num2str(iter)]);
    %         % p-> overgridded G->normal image dims
    %         tic
    %         reconObj.wt.pipe = abs(reconObj.wt.pipe ./ ...
    %             (reconObj.G * (reconObj.G'*reconObj.wt.pipe)));
    %         disp(['Finished itter ' num2str(iter) ' in ' num2str(toc) ' seconds']);
    %     end
    
    options.reconObj = reconObj;
end

%% Reconstruct image
disp('Reconstructing data...');
% Uses exp_xform_mex.c
tic;
recon_vol = reshape(options.reconObj.G' * ...
    (options.reconObj.wt.pipe .* data(:) ),options.reconObj.G.idim);

% % Overgridded fft image
% recon_vol2 = fftshift(reshape(options.reconObj.G.arg.Gnufft.arg.st.p' * ...
%     (options.reconObj.wt.pipe .* data(:) ),options.reconObj.G.arg.Gnufft.arg.st.Kd));
% figure();
% imslice(log(abs(recon_vol2)));

% overgridded image
% recon_vol = circshift(ifftn(reshape(options.reconObj.G.arg.Gnufft.arg.st.p' * ...
%     (options.reconObj.wt.pipe .* data(:) ),options.reconObj.G.arg.Gnufft.arg.st.Kd)),...
%     [options.reconObj.G.arg.Gnufft.arg.st.Kd - options.reconObj.G.idim]/2);

% %overgridded image ungridded - no scaling!
% recon_vol = ifftn(reshape(options.reconObj.G.arg.st.p' * ...
%     (options.reconObj.wt.pipe .* data(:) ),options.reconObj.G.arg.st.Kd));
% idim = reconObj.G.idim
% recon_vol = recon_vol(1:idim(1),1:idim(2),1:idim(3));

% Third output is reconObject (useful to speed up multiple similar recons)
if(nargout > 2)
    varargout{2} = options.reconObj;
end

end %function