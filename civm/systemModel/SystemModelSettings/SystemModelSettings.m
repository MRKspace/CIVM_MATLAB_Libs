classdef SystemModelSettings
	properties
		outputSize;
		overgridSize;
	end
	methods
		function obj = SystemModelSettings(output_size,overgrid_size)
			obj.outputSize = output_size;
			obj.overgridSize = overgrid_size;
		end
		function true_false = isCompatible(obj,header,overgridfactor)
			true_false = true;
			if(header.MatrixSize ~= obj.outputSize)
				true_false = false
			elseif(overgridfactor*header.MatrixSize ~= obj.overgridSize)
				true_false = false;
			end
		end
	end
end
