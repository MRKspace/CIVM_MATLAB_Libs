classdef GriddingSystemModelSettings < SystemModelSettings
	properties
		kernelWidth;
	end
	methods
		function obj = GriddingSystemModelSettings(output_size,overgrid_size,kernel_width)
			% Call super constructor
            obj = obj@SystemModelSettings(output_size,overgrid_size);
			obj.kernelWidth = kernel_width;
		end
		function true_false = isCompatible(obj,header,overgridfactor,neighborhood_size)
			if(neighborhood_size ~= obj.kernelWidth)
				true_false = false;
			else
				true_false = isCompatible@SystemModelSettings(obj,...
					header,overgridfactor);
			end
		end
	end
end
