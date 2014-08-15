classdef ConjGradReconSettings
	properties
		nIter;
		saveIter;
	end
	methods
		function obj = ConjGradReconSettings(n_iter, save_iter)
			obj.nIter = n_iter;
			obj.saveIter = save_iter;
		end
		function true_false = isCompatible(obj,dcf_iter)
			true_false = (obj.nIter == dcf_iter);
		end	
	end
end