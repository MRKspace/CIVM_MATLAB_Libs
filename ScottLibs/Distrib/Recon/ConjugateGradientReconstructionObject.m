classdef ConjugateGradientReconstructionObject < AbstractReconstructionObject
    properties
        wi;
    end
    
    methods
        function obj = ConjugateGradientReconstructionObject(traj, N, J, K)
            % Call super constructor to build recon obj
            obj = obj@AbstractReconstructionObject(traj, N, J, K);
        end
                
        % Reconstructs an image using the given data
        function recon_vol = reconstruct(obj,data, iter)
            disp('Reconstructing data...');
            recon_vol = qpwls_pcg1(0*obj.A.arg.mask, obj.A, 1, data, 0, ...
                'niter', iter, 'isave',1:iter);
            recon_vol  = reshape(recon_vol, [size(obj.A.arg.mask) iter]);

        end
    end
end
