classdef LsqRecon < Recon
	properties
		dcfObj;
	end
	methods
		% Constructor
		function obj = LsqRecon(system_model, dcf_obj, verbose)
			% Call super constructor to build recon obj
			obj = obj@Recon(system_model,verbose);
			
			% Store properties
			obj.dcfObj = dcf_obj;
			
			obj.unique_string = ['lsqRecon_' obj.model.unique_string '_' obj.dcfObj.unique_string];
		end
		
		% Reconstructs an image volume using the given data
		function reconVol = reconstruct(obj,data,snr_weights)
			if(obj.verbose)
				disp('Reconstructing image...');
			end
			switch(obj.dcfObj.dcf_style)
				case 'gridspace'
					nonzero_dcf = (obj.dcfObj.dcf~=0);					
					reconVol = (obj.model.A' * data);
					reconVol(nonzero_dcf) = reconVol(nonzero_dcf) .* obj.dcfObj.dcf(nonzero_dcf);
				case 'dataspace'
					reconVol = obj.model.A' * (obj.dcfObj.dcf .* data);
					
					% We want to solve A'*W*A*x = A'*W*y
% 					if(obj.verbose)
% 						disp('Starting itterative SNR compensation');
% 					end
% 					% 					Afun = @(x,transp_flag) obj.model.A'*(snr_weights.*(obj.model.A*x));
% 					% 					b = obj.model.A'*(snr_weights.*dcf_obj.dcf.*data);
% 					% 					reconVol = gmres(Afun, b,1,[],5,[],[],reconVol);
% 					
% 					init_guess = ones(size(reconVol));
% 					nIter = 100;
% 					
% 					% Do we not need density compensation then?
% 					Afun_old = @(x,transp_flag) x;
% 					b_old = obj.model.A'*(dcf_obj.dcf.*data);
% 					recon_old = gmres(Afun_old, b_old,1,[],nIter,[],[],init_guess);
% 					im_old = fftshift(fftn(reshape(full(recon_old),obj.model.reconMatrixSize)));
% 					im_old = im_old(1:128,1:128,1:128);
% 					figure();imslice(abs(im_old),'old');
% 					nii = make_nii(abs(im_old),16);
% 					save_nii(nii,['old_' num2str(nIter) 'iter.nii']);
% 					
% 					Afun_new = @(x,transp_flag) obj.model.A'*(dcf_obj.dcf.*snr_weights.*(obj.model.A*x));
% 					b_new = obj.model.A'*(dcf_obj.dcf.*snr_weights.*data);
% 					recon_new = gmres(Afun_new, b_new,1,[],nIter,[],[],init_guess);	
% 					im_new = fftshift(fftn(reshape(full(recon_new),obj.model.reconMatrixSize)));
% 					im_new = im_new(1:128,1:128,1:128);					
% 					figure();imslice(abs(im_new),'new');
% 					nii = make_nii(abs(im_new),16);
% 					save_nii(nii,['new_' num2str(nIter) 'iter.nii']);
% 					
% 					diffim = abs(im_new-im_old);
% 					nii = make_nii(abs(diffim),16);
% 					save_nii(nii,['diff_' num2str(nIter) 'iter.nii']);
% 					
% 					reconVol = recon_new;
					
				otherwise
					error('DCF style not recognized');
			end
			reconVol = reshape(full(reconVol),obj.model.reconMatrixSize);
			if(obj.verbose)
				disp('Finished Reconstructing image.');
			end
		end
		
		function true_false = isCompatible(obj,model,dcf_iter)
			% Ask if super constructor is compatible
			true_false = (obj.isCompatible@Recon(model));
			
			% CHECK IF MODEL IS COMPATIBLE
			
			if(~obj.settings.isCompatible(dcf_iter))
				true_false = false;
			end
		end
	end
end
