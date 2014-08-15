classdef GenericReconstruction < Recon
	properties
		ActualRecon;
		ReconType;
	end
	
	methods
		function obj = GenericReconstruction(model,iterations,recon_type)
			% Call super constructor with dummy settings (replaced later)
			obj = obj@Recon(model,[]);
			
			% ignore case
			obj.ReconType = lower(recon_type);
			
			% Decide what model to use
			if(strcmp(recon_type,'lsq'))
				% Replace proper settings to object
				obj.settings = LsqReconSettings(iterations);
				
				% Make Least Squares Recon Object
				obj.ActualRecon = LsqRecon(model,obj.settings);
			elseif(~isempty(strfind(model_type,'cg')))
				% Replace proper settings to object
				obj.settings = ConjGradReconSettings(iterations, 1:iterations);
				
				% Make Conjugate Gradient Recon Object
				obj.ActualRecon = ConjGradRecon(model, obj.settings);
			end
		end
		
		% Reconstructs an image volume using the given data using the real
		% Recon object
		function reconVol = reconstruct(obj,data)
			reconVol  = obj.ActualRecon.reconstruct(data);
		end
		
		function true_false = isCompatible(obj,model,dcf_iter,recon_type)
			true_false = obj.ActualRecon.isCompatible(model,dcf_iter);
			if(~streq(obj.ReconType,recon_type))
				true_false = false;
			end
		end
	end
end
