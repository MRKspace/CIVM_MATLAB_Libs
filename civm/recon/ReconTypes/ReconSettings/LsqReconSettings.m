classdef LsqReconSettings
	properties
		nDcfIter;
	end
	methods
		function obj = LsqReconSettings(n_dcf_iter)
			obj.nDcfIter = n_dcf_iter;
		end
		
		function true_false = isCompatible(obj,dcf_iter)
			true_false = (obj.nDcfIter == dcf_iter);
		end	
	end
end