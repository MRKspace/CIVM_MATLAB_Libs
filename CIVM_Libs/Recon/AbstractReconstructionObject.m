classdef AbstractReconstructionObject
    properties
        A;
    end
    
    methods
        % Constructor
        function obj = AbstractReconstructionObject(traj, N, J, K)
            % optimize min-max error accross volume
            obj.A = Gmri(traj, true(N), 'fov', N, 'nufft_args', ...
                {N,J,K,N/2,'minmax:kb'});
        end
    end
    
    methods (Abstract)
        % Reconstructs an image using the given data
        recon_vol = reconstruct(obj,data);
    end
end
