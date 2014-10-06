classdef GriddingSystemModel < SystemModel
	properties
		outputImageSize;
		overgridFactor;
		neighborhoodSize;
		kaiser_b;
		proximetyObj;
		verbose;
	end
	methods
		function obj = GriddingSystemModel(traj, samp_snr, output_image_size, ...
				overgrid_factor, neighborhood_size, proxObj, verbosity)
			
			% Initialize properties
			obj.outputImageSize = output_image_size;
			obj.overgridFactor = overgrid_factor;
			obj.neighborhoodSize = neighborhood_size * overgrid_factor;
			obj.reconMatrixSize = ceil(output_image_size * overgrid_factor);
			obj.proximetyObj = proxObj;
			obj.unique_string = ['griddingModel_' proxObj.unique_string];
			obj.verbose = verbosity;
						
			%Apply proximity info and create sparse system matrix;			
			if(obj.verbose)
				disp('Calculating kernel values...');
			end
			
			obj.A = obj.proximetyObj.kernelValues(traj,...
				obj.neighborhoodSize,...
				obj.reconMatrixSize,obj.overgridFactor);
			if(obj.verbose)
				disp('Finished calculating kernel values.');
			end
			
% 			% Figure out the weighting of each voxel
% 			vox_weight = full(sum(obj.A,1));
% 			n = length(vox_weight);
% 			vox_weight = spdiags(1./vox_weight(:),0,n,n);
% 			obj.A = obj.A*vox_weight;
		end
		
		function obj = imageSpace(obj)
			obj.reconVol = imageSpace@SystemModel(obj,obj.reconVol);
			
			%  Shift data by fov/4
			% 			reconVol = circshift(reconVol,round(0.5*(obj.reconMatrixSize-obj.outputImageSize)));
			obj.reconVol = circshift(obj.reconVol,0.5*obj.outputImageSize);
			
			% Crop BL corner
			obj.reconVol = obj.reconVol(1:obj.outputImageSize(1),...
				1:obj.outputImageSize(2), ...
				1:obj.outputImageSize(3));
			
						% Deapodize - consider making at lower res
			obj.reconVol = obj.proximetyObj.deapodize(obj.neighborhoodSize,1,obj.outputImageSize,obj.reconVol);
			
% 			% center the DC freq
% 			obj.reconVol = fftshift(obj.reconVol);
% 			
% 			% Deapodize - consider making at lower res
% 			obj.reconVol = obj.proximetyObj.deapodize(obj.neighborhoodSize,obj.overgridFactor,obj.reconMatrixSize,obj.reconVol);
% 			
% 			% Uncenter the DC freq
% 			obj.reconVol = fftshift(obj.reconVol);
% 			
% 			%  Shift data by fov/4
% 			% 			reconVol = circshift(reconVol,round(0.5*(obj.reconMatrixSize-obj.outputImageSize)));
% 			obj.reconVol = circshift(obj.reconVol,0.5*obj.outputImageSize);
% 			
% 			% Crop BL corner
% 			obj.reconVol = obj.reconVol(1:obj.outputImageSize(1),...
% 				1:obj.outputImageSize(2), ...
% 				1:obj.outputImageSize(3));
		end
		
		function true_false = isCompatible(obj,traj,header,overgridfactor,nNeighbors);
			true_false = false;
		end
	end
end