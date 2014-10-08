classdef GenericSystemModel < SystemModel
	properties
		ActualModel;
	end
	methods
		function obj = GenericSystemModel(traj,header,overgridfactor,nNeighbors,model_type)
			% Call super constructor with dummy settings (replaced later)
            obj = obj@SystemModel(traj,[]);
			
			% ignore case
			model_type = lower(model_type);
			
			% Create common settings
			N = header.MatrixSize;
			K = N*overgridfactor;
			
			% Decide what model to use
			if(strcmp(model_type,'nufft'))
				% Create NUFFT model settings
				J = [nNeighbors nNeighbors nNeighbors];
				
				% Replace proper settings to object
				obj.settings = NufftSystemModelSettings(N,K,J);
				
				% Make NUFFT model
				obj.ActualModel = NufftSystemModel(traj,obj.settings);
			elseif(~isempty(strfind(model_type,'grid')))
				% Replace proper settings to object
				obj.settings = GriddingSystemModelSettings(N,K,nNeighbors);
				
				% Make a gridding model
				obj.ActualModel = GriddingSystemModel(traj,obj.settings);
			end
			
			% Make A matrix just point to the Actual Model
			obj.A = obj.ActualModel.A;
		end
		
		function true_false = isCompatible(obj,traj,header,overgridfactor,nNeighbors)
			true_false = obj.ActualModel.isCompatible(traj,header,overgridfactor,nNeighbors);
		end
	end
end