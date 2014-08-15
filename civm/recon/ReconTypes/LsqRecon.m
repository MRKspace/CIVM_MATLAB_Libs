classdef LsqRecon < Recon
	properties
		dcf;
		dcfIterations;
	end
	
	methods
		% Constructor
		function obj = LsqRecon(system_model, dcf_iterations, verbose)
			% Call super constructor to build recon obj
			obj = obj@Recon(system_model,verbose);
			
			% Store properties of reconObj
			obj.dcfIterations = dcf_iterations;
			
			obj.dcf = 1./abs(obj.model.A * ones(prod(obj.model.reconMatrixSize),1)); % Reasonable first guess
			
			% Calculate density compensation using Pipe method
			if(obj.verbose)
					disp('Calculating density compensation values...');
			end
			for iter = 1:obj.dcfIterations
				if(obj.verbose)
					disp(['   DCF Iteration:' num2str(iter)]);
				end
				obj.dcf = abs(obj.dcf ./ (obj.model.A * (obj.model.A'*obj.dcf)));
			end
			if(obj.verbose)
					disp('Finished calculating density compensation values.');
			end
		end
		
		% Reconstructs an image volume using the given data
		function reconVol = reconstruct(obj,data)
			if(obj.verbose)
					disp('Reconstructing image...');
			end
			reconVol = obj.model.A' * (obj.dcf .* data);
			reconVol = reshape(full(reconVol),obj.model.reconMatrixSize);	
			if(obj.verbose)
					disp('Finished Reconstructing image.');
			end
		end
		
		function true_false = isCompatible(obj,model,dcf_iter)
			
			
			% Ask if super constructor is compatible
			true_false = (obj.isCompatible@Recon(model));
			
			% CHECK IF MODEL IS COMPATIBLE
			
			if(~obj.settings.isCompatible(dcf_iter))
				true_false = false;
			end
		end
	end
end
