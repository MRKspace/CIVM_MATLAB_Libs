classdef NufftSystemModelSettings < SystemModelSettings
	properties
		neighborhoodSize;
	end
	methods
		function obj = NufftSystemModelSettings(output_size,overgrid_size,neighborhood_size)
			% Call super constructor
            obj = obj@SystemModelSettings(output_size,overgrid_size);
			obj.neighborhoodSize = neighborhood_size;
		end
		function true_false = isCompatible(obj,header,overgridfactor,neighborhood_size)
			if(neighborhood_size ~= obj.neighborhoodSize)
				true_false = false;
			else
				true_false = isCompatible@SystemModelSettings(obj,...
					header,overgridfactor);
			end
		end
	end
end
