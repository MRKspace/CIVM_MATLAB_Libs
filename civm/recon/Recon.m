classdef Recon
	properties
		model;			% System Matrix
		verbose;
		unique_string;
	end
	
	methods
		function obj = Recon(system_model, is_verbose)
			% Save the System Matrix
			obj.model = system_model;
			obj.verbose = is_verbose;
		end
		
		function true_false = isCompatible(obj,the_model)
			true_false = true;
		end
	end
	
	methods (Abstract)
		% Reconstructs an image volume using the given data
		reconVol = reconstruct(obj,data);
	end
end
