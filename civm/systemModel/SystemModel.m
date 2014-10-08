classdef SystemModel
	properties
		reconMatrixSize;
		A;					% System Representation
		unique_string;
		reconVol;
	end
	methods
		function reconVol = imageSpace(obj, reconVol)
			reconVol = ifftn(reconVol);
		end
	end
	methods (Abstract)
		true_false = isCompatible(obj,traj,header,overgridfactor,nNeighbors);
	end
end
