classdef ConjugatePhaseReconstructionObject < AbstractReconstructionObject
    properties
        wi;
    end
    
    methods
        function obj = ConjugatePhaseReconstructionObject(traj, header, overgridfactor, scale, nNeighbors, useAllPoints, dcf_iter)
            % Call super constructor to build recon obj
            obj = obj@AbstractReconstructionObject(traj, header, overgridfactor, scale, nNeighbors, useAllPoints);
            
            % Calculate Density compenstion
            obj = obj.calculateDCF(dcf_iter);
        end
        
        % Calculates density compensation values using Pipe's paper
        function obj = calculateDCF(obj, dcf_iter)
            disp('Itteratively calculating density compensation coefficients...');
            obj.wi = 1./abs(obj.A.arg.Gnufft.arg.st.p * ...
                ones(obj.A.arg.Gnufft.arg.st.Kd)); % Reasonable first guess
            
            % Calculate density compensation using Pipe method
            for iter = 1:dcf_iter
                disp(['   Iteration:' num2str(iter)]);
                obj.wi = abs(obj.wi ./ ((obj.A.arg.Gnufft.arg.st.p * ...
                    (obj.A.arg.Gnufft.arg.st.p'*obj.wi))));
            end
        end
        
        % Reconstructs an image using the given data
        function recon_vol = reconstruct(obj,data)
            disp('Reconstructing data...');
            recon_vol = obj.A' * (obj.wi .* data(:));
            recon_vol = reshape(recon_vol,obj.A.idim);
        end
    end
end
