classdef AbstractReconstructionObject
    properties
        A;
    end
    
    methods
        % Constructor
        function obj = AbstractReconstructionObject(traj, header, overgridfactor, scale, nNeighbors, useAllPts)
            inv_scale = 1/scale;
            N = floor(scale*header.MatrixSize);
            if(useAllPts)
                traj = 0.5*traj;
                N = 2*N;
            end
            J = [nNeighbors nNeighbors nNeighbors];
            K = ceil(N*overgridfactor);
            
            %% Throw away data outside the BW
            throw_away = find((traj(:,1)>0.5) + (traj(:,2)>0.5) + (traj(:,3)>0.5) + ...
                (traj(:,1)<-0.5) + (traj(:,2)<-0.5) + (traj(:,3)<-0.5));
            traj(throw_away(:),:)=[];
            data(throw_away(:))=[];
            
            % optimize min-max error accross volume
            obj.A = Gmri(inv_scale*traj, true(N), 'fov', N, 'nufft_args', {N,J,K,N/2,'minmax:kb'});
        end
    end
    
    methods (Abstract)
        % Reconstructs an image using the given data
        recon_vol = reconstruct(obj,data);
    end
end
