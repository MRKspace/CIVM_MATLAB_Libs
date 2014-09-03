classdef HitplaneDcf < DCF
	methods
		% Constructor
		function obj = HitplaneDcf(model, verbosity)
			% Store properties of DCF
			obj.verbose = verbosity;
			obj.dcf_type = 'hitplane';
			obj.dcf_unique_name = 'hitplaneDcf';
			obj.dcf_style = 'gridspace';
			
			% Note - hitplane DCF is on the overall kspace image,
			% not the data itself (dimension of kspace not data)
			if(isa(model.A,'Fatrix'))
				%Handle silly Fessler object
				obj.dcf = sum(model.A.arg.G~=0,1)';
			else
				obj.dcf = sum(model.A~=0,1)';
			end
			obj.dcf = full(obj.dcf); 
			nonzero_vals = (obj.dcf~=0);
			obj.dcf(nonzero_vals) = 1./(model.neighborhoodSize*obj.dcf(nonzero_vals));
		end
	end
end