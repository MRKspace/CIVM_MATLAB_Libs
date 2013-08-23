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

% if you dont have all the data, trajectories, weights, or header, read
% them in. This check is for repeat reconstructions in order to save some
% time for things like itterative recon
if(~isfield(options, 'data') || ...
        ~isfield(options, 'traj') || ...
        ~isfield(options, 'weights') || ...
        ~isfield(options, 'header'))
    
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
end

% Override calculated values (needed after file reading for dual psd)
if(isfield(options, 'traj'))
    traj = options.traj;
end

if(isfield(options, 'data'))
    data = options.data;
end

if(isfield(options, 'weights'))
    weights = options.weights;
end

if(isfield(options, 'header'))
    header = options.header;
end

% If recon object is provided, make sure it matches the input data
% reasonably well.
needsreconObjConstruction = 1;
if(isfield(options, 'reconObj'))
    if(isfield(options, 'exact') & options.exact & options.reconObj.G.arg.exact)
        N = floor(options.scale*header.MatrixSize);
        
        if(N ~=options.reconObj.G.Nd)
            error('Output image size of reconObj does not match data.');
        elseif(size(traj) ~= size(reconObj.G.arg.kspace))
            error('Different number of trajectory values in data and reconObj');
        elseif(traj ~= reconObj.G.arg.kspace)
            error('Trajectory values are different between data and reconObj');
        end
        needsreconObjConstruction = 0;
    elseif(~isfield(options, 'exact') || (~options.exact & ~options.reconObj.G.arg.exact))
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
        needsreconObjConstruction = 0;
    end
end
if(needsreconObjConstruction)
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
    if(~isfield(options, 'exact'))
        options.exact = 0;
    end
    if(~isfield(options, 'exact_dct_iter'))
        options.exact_dct_iter = 0;
    end
    
    %% Calculate Sample Density Corrections
    inv_scale = 1/options.scale;
    N = floor(options.scale*header.MatrixSize);
    2*round((N-1)/2)+1; % Make sure N is even
    J = [options.nNeighbors options.nNeighbors options.nNeighbors];
    K = ceil(N*options.overgridfactor);
    
    % optimize min-max error accross volume
    reconObj.G = Gmri(inv_scale*traj, true(N), 'fov', N, 'nufft_args', {N,J,K,N/2,'kaiser'});
    clear N K J traj nuft_a;
    
    disp('Itteratively calculating density compensation coefficients...');
    reconObj.wt.pipe = 1./abs(reconObj.G.arg.Gnufft.arg.st.p * ...
        ones(reconObj.G.arg.Gnufft.arg.st.Kd)); % Reasonable first guess
    reconObj.wt.max_itter = options.dcf_iter;
    
    % Calculate density compensation using Pipe method
    for iter = 1:options.dcf_iter
        disp(['   Iteration:' num2str(iter)]);
        reconObj.wt.pipe = abs(reconObj.wt.pipe ./ ...
            ((reconObj.G.arg.Gnufft.arg.st.p * ...
            (reconObj.G.arg.Gnufft.arg.st.p'*(reconObj.wt.pipe)))));
    end
    
    %Exact Fourier transform recon
    if(options.exact)
        reconObj.G = Gmri(reconObj.G.Nd(1)*reconObj.G.arg.kspace, ...
            true(reconObj.G.Nd), 'exact', 1, 'n_shift', ...
            reconObj.G.arg.nufft_args{1}/2);
        
        if(options.exact_dct_iter > 0)
            disp('Itteratively calculating DCF for exact FFT...');
            start_t = toc;
            for iter = 1:options.exact_dct_iter
                disp(['   Iteration:' num2str(iter)]);
                
                reconObj.wt.pipe = abs(reconObj.wt.pipe ./ ...
                    (reconObj.G * (reconObj.G'*reconObj.wt.pipe)));
                
                
                disp(['Calculated itter ' num2str(iter) ' in ' ...
                    num2str(toc-start_t) ' seconds.']);
            end
            disp(['Finished calculating DCF.']);
        end
    end
    
    options.reconObj = reconObj;
end

%% Calculate RF Decay weighting and DC amplification
% dc_amp = 1./weights;
% weights = sqrt(weights);
% rf_weights = abs(weights ./ ((options.reconObj.G.arg.Gnufft.arg.st.p * (options.reconObj.G.arg.Gnufft.arg.st.p'*(weights.*options.reconObj.wt.pipe)))));
% rf_weights = rf_weights/max(rf_weights(:));

%% Reconstruct image
disp('Reconstructing data...');
% Uses exp_xform_mex.c if exact recon
recon_vol = reshape(options.reconObj.G' * ...
    (options.reconObj.wt.pipe .* data(:))...
    ,options.reconObj.G.idim);

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