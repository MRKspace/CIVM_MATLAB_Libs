classdef ConjGradRecon < Recon
	properties
		iterations;
		saveIterations;
	end
	methods
		function obj = ConjGradRecon(system_model, iter, saveIter, verbose)
			% Call super constructor to build recon obj
			obj = obj@Recon(system_model, verbose);
			
			% Save properties
			obj.iterations = iter;
			obj.saveIterations = saveIter;
		end
		
		% Reconstructs an image volume using the given data
		function reconVol = reconstruct(obj,data)
			C = 0;
		
			reconVol = qpwls_pcg1(zeros(obj.model.reconMatrixSize), obj.model.A, 1, data, C, ...
				'niter', obj.iterations, 'isave',obj.saveIterations);

			reconVol  = reshape(reconVol, [obj.model.reconMatrixSize ...
				length(obj.saveIterations)]);
		end
		
		function true_false = isCompatible(obj,model,dcf_iter)
			% Ask if super constructor is compatible
			true_false = (obj.isCompatible@Recon(model));
			
			if(~obj.settings.isCompatible(dcf_iter))
				true_false = false;
			end
		end
	end
end
