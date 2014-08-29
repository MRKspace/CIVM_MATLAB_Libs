%   Pipe, J. G., & Menon, P. (1999). Sampling density compensation in MRI:
%   rationale and an iterative numerical solution. Magnetic resonance in
%   medicine : official journal of the Society of Magnetic Resonance in
%   Medicine / Society of Magnetic Resonance in Medicine, 41(1), 179–86.
%   Retrieved from http://www.ncbi.nlm.nih.gov/pubmed/10025627
classdef IterativeDcf < DCF
		properties
			dcf_iterations;
		end
	methods
		% Constructor
		function obj = IterativeDcf(model, iterations, verbosity)
			% Store properties of DCF
			obj.verbose = verbosity;
			obj.dcf_iterations = iterations;
			obj.dcf_type = 'iterative';
			obj.dcf_unique_name = ['iterativeDcf' num2str(obj.dcf_iterations) 'iter'];
			obj.dcf_style = 'dataspace';
						
			obj.dcf = 1./abs(model.A * ones(prod(model.reconMatrixSize),1)); % Reasonable first guess
			for iter = 1:obj.dcf_iterations
				if(obj.verbose)
					disp(['   DCF Iteration:' num2str(iter)]);
				end
				obj.dcf = abs(obj.dcf ./ (model.A * (model.A'*obj.dcf)));
			end
		end
	end
end