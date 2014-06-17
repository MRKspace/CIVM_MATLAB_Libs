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
		function recon_vol = reconstruct(obj,data, iter,save_iter)
			disp('Reconstructing data...');
			
			C = Cdiffs(size(obj.A.arg.mask), 'type_diff', 'circshift', ...
				'offsets', '3d:26');
			recon_vol = qpwls_pcg1(0*obj.A.arg.mask, obj.A, 1, data, C, ...
				'niter', iter, 'isave',save_iter);

			recon_vol  = reshape(recon_vol, [size(obj.A.arg.mask) length(save_iter)]);
			
		end
	end
end
