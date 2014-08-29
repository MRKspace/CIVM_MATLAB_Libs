classdef AnalyticalDcf < DCF
	methods
		% Constructor
		function obj = AnalyticalDcf(traj, verbosity)
			% Store properties of DCF
			obj.verbose = verbosity;
			obj.dcf_type = 'analytical';
			obj.dcf_unique_name = 'analyticalDcf';
			obj.dcf_style = 'dataspace';
			
			obj.dcf = sqrt(sum(traj.^2,2));
		end
	end
end
