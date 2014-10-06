classdef OptimalGriddingKernel < GriddingKernel
	properties
		kernel_width;
		overgrid_factor;
		norm_val;
		nIter;
		interp_values;
		interp_dist;
	end
	
	methods
		% Constructor
		function obj = OptimalGriddingKernel(kern_width, imageSize, overgridFactor, lut_size, iter, verbose)
			% Call super constructor to build obj
			obj = obj@GriddingKernel(verbose);
			
			% Store properties
			obj.kernel_width = kern_width;
			obj.overgrid_factor = overgridFactor;
			obj.nIter = iter;
			
			if(obj.verbose)
				disp('Optimizing kernel...');
			end
			
			kern_size_k = obj.kernel_width/imageSize;
			
			k_lsp_fine = linspace(-0.5, 0.5, lut_size+1);
			k_lsp_fine = k_lsp_fine(1:(end-1));
			delta_k = k_lsp_fine(2)-k_lsp_fine(1);
			
			i_lsp_fine = linspace(-0.5/delta_k,0.5/delta_k,overgridsize*lut_size);
			
			% Create binary bounding functions
			k_bound = (abs(k_lsp_fine) <= (0.5*kern_size_k));
			i_bound = (abs(i_lsp_fine) <= 0.5*imageSize);
			
			% Create plot bounds
			k_plot = (abs(k_lsp_fine) <= kern_size_k);
			i_plot = (abs(i_lsp_fine) <= imageSize*obj.overgrid_factor);
			
			% Start with bounded kernel
			k_kern = k_bound;
			i_kern = zeros(size(i_lsp_fine)); % dummy initialization
			
			% Start with Spatially bounded signal
			i_kern = ones(size(i_lsp_fine));
			k_kern = zeros(size(i_lsp_fine)); % dummy initialization
			
			for iBound = 1:obj.nIter
				if(obj.verbose)
					disp(['Kernel optimization ' num2str(iBound) '/' num2str(obj.nIter)]);
				end
				% Calculate kernel in freq domain
				k_kern = fftshift(fftn(i_kern));
				
								figure(1);
								subplot(1,2,1);
								plot(k_lsp_fine(k_plot)*imageSize,abs(k_kern(k_plot)));
								% 	set(gca,'XTick',(kern_width-0.5*([1:kern_width]-1)));
								title('Kspace kernel');
								subplot(1,2,2);
								plot(i_lsp_fine(i_plot),abs(i_kern(i_plot)));
								set(gca,'XTick',0.5*[-imageSize imageSize],'XTickLabel',{'-FOV/2','FOV/2'});
								title('Image kernel');
				
				% Enforce that its all real
% 				k_kern = abs(k_kern);
				
				% Bound kernel in freq domain
				k_kern = k_bound.*k_kern;
				
				% Normalize kernel
				k_kern = k_kern/max(k_kern(:));
				
				% Calculate spatial kernel
				i_kern = ifftn(ifftshift(k_kern));
				
								figure(1);
								subplot(1,2,1);
								plot(k_lsp_fine(k_plot)*imageSize,abs(k_kern(k_plot)));
								% 	set(gca,'XTick',(kern_width-0.5*([1:kern_width]-1)));
								title('Kspace kernel');
								subplot(1,2,2);
								plot(i_lsp_fine(i_plot),abs(i_kern(i_plot)));
								set(gca,'XTick',0.5*[-imageSize imageSize],'XTickLabel',{'-FOV/2','FOV/2'});
								title('Image kernel');
				
				% Bound kernel in spatial domain
				i_kern = i_bound.*i_kern;
			end
			
			% Calculate normalization value
			obj.interp_values = k_kern(k_bound)/max(k_kern(k_bound));
			obj.interp_dist = k_lsp_fine(k_bound)*imageSize;
			
			if(obj.verbose)
				disp('Finished optimizing kernel.');
			end
			
			% Fill in unique string
			obj.unique_string = ['optimal_width' num2str(obj.kernel_width) ...
				'_obj.overgrid_factor' num2str(obj.overgrid_factor)...
				'_nIter' num2str(obj.nIter)];
		end
		
		function [kernel_vals] = kernelValues(obj, distances)
			if(obj.verbose)
				disp('Calculating kernel values...');
			end
			kernel_vals = interp1(obj.interp_dist,abs(obj.interp_values),distances);
			if(obj.verbose)
				disp('Finished calculating kernel values.');
			end
		end
	end
end