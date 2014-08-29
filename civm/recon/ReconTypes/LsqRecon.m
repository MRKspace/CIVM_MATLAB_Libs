classdef LsqRecon < Recon
	methods
		% Constructor
		function obj = LsqRecon(system_model, verbose)
			% Call super constructor to build recon obj
			obj = obj@Recon(system_model,verbose);
		end
		
		% Reconstructs an image volume using the given data
		function reconVol = reconstruct(obj,data,dcf_obj)
			if(obj.verbose)
				disp('Reconstructing image...');
			end
			switch(dcf_obj.dcf_style)
				case 'gridspace'
					nonzero_dcf = (dcf_obj.dcf~=0);
					reconVol = (obj.model.A' * data);
					reconVol(nonzero_dcf) = reconVol(nonzero_dcf) ./ dcf_obj.dcf(nonzero_dcf);
				case 'dataspace'
					reconVol = obj.model.A' * (dcf_obj.dcf .* data);
				otherwise
					error('DCF style not recognized');
			end
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
