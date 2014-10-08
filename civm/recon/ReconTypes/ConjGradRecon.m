classdef ConjGradRecon < Recon
	properties
		iterations;
		saveIterations;
		dcfObj;
	end
	methods
		function obj = ConjGradRecon(system_model, dcf_obj, iter, saveIter, verbose)
			% Call super constructor to build recon obj
			obj = obj@Recon(system_model, verbose);
			
			% Save properties
			obj.iterations = iter;
			obj.saveIterations = saveIter;
			obj.dcfObj = dcf_obj;
			obj.unique_string = ['cgRecon_iter' num2str(obj.iterations) obj.model.unique_string];
		end
		
		% Reconstructs an image volume using the given data
		function reconVol = reconstruct(obj,data, weights,x,userFun,details)
			% 			C = 0;
			%
			% 			reconVol = qpwls_pcg1(startingGuess, obj.model.A, Gdiag((1/mean(abs(data(:))))*weights), data, C, ...
			% 				'niter', obj.iterations, 'isave',obj.saveIterations, 'userfun', userFun);
			%
			% 			reconVol  = reshape(reconVol, [obj.model.reconMatrixSize ...
			% 				length(obj.saveIterations)]);
			
			
			
			
			
			% 								We want to solve A'*W*A*x = A'*W*y
			if(obj.verbose)
				disp('Starting itterative SNR compensation');
			end
			
			x = x(:);
			
			switch(obj.dcfObj.dcf_style)
				case 'gridspace'
					Afun = @(x,transp_flag) (obj.model.A'*(weights.*obj.dcfObj.dcf.*(obj.model.A*x)));
					b = obj.model.A'*weights.*obj.dcfObj.dcf.*data(:);
					for(iIter=1:obj.iterations)
						disp(['Iteration ' num2str(iIter)]);
						
						x = lsqr(@aFunNoSNR, b,0,1,[],[],x);
						
						userFun(reshape(x,[obj.model.reconMatrixSize]), iIter, details);
					end
					% 					nonzero_dcf = (obj.dcfObj.dcf~=0);
					% 					reconVol = (obj.model.A' * data);
					% 					reconVol(nonzero_dcf) = reconVol(nonzero_dcf) .* obj.dcfObj.dcf(nonzero_dcf);
				case 'dataspace'
					% 					reconVol = obj.model.A' * (obj.dcfObj.dcf .* data);
					b = obj.model.A'*(weights.*obj.dcfObj.dcf.*data);
% 					for(iIter=1:obj.iterations)
% 						disp(['Iteration ' num2str(iIter)]);
						
						[x,flag,relres,iter,resvec] = lsqr(@aFunSNR, b,0,obj.iterations,[],[],x);
						
						userFun(reshape(x,[obj.model.reconMatrixSize]), obj.iterations, details);
% 					end
				otherwise
					error('DCF style is not supported');
			end
			
			
			% 			% SNR weighted
			% 			Afun = @(x,transp_flag) obj.model.A'*(weights.*(obj.model.A*x));
			% 			b = obj.model.A'*(weights.*data);
			% 			for(iIter=1:obj.iterations)
			% 				disp(['Iteration ' num2str(iIter)]);
			% 				% 				x = pcg(Afun, b,[],1,[],[],x);
			% 				x = gmres(Afun, b,1,[],1,[],[],x);
			% 				userFun(reshape(x,[obj.model.reconMatrixSize]), iIter, details);
			% 			end
			
% 			% SNR, DCF weighted
% 			% 			Afun = @(x,transp_flag) obj.model.A'*((obj.model.A*x));
% 			% 			b = obj.model.A'*data;
% 			Afun = @(x,transp_flag) (obj.model.A*x);
% 			b = data(:);
% 			for(iIter=1:obj.iterations)
% 				disp(['Iteration ' num2str(iIter)]);
% 				
% 				x = lsqr(@aFunNoSNR, b,0,1,[],[],x);
% 				
% 				userFun(reshape(x,[obj.model.reconMatrixSize]), iIter, details);
% 			end
			
			% 			% Not SNR weighted
			% 			% 			Afun = @(x,transp_flag) obj.model.A'*((obj.model.A*x));
			% 			% 			b = obj.model.A'*data;
			% 			Afun = @(x,transp_flag) (obj.model.A*x);
			% 			b = data(:);
			% 			for(iIter=1:obj.iterations)
			% 				disp(['Iteration ' num2str(iIter)]);
			%
			% 				x = lsqr(@aFunNoSNR, b,0,1,[],[],x);
			%
			% 				userFun(reshape(x,[obj.model.reconMatrixSize]), iIter, details);
			% 			end
			
			%
			% 			Afun = @(x,transp_flag) x;
			% 			b_old = obj.model.A'*(dcf_obj.dcf.*data);
			% 			recon_old = gmres(Afun, b_old,1,[],nIter,[],[],init_guess);
			%
			reconVol = reshape(full(x),obj.model.reconMatrixSize);
			% 			im_new = fftshift(fftn(reshape(full(recon_new),obj.model.reconMatrixSize)));
			% 			im_new = im_new(1:128,1:128,1:128);
			% 			figure();imslice(abs(im_new),'new');
			% 			nii = make_nii(abs(im_new),16);
			% 			save_nii(nii,['new_' num2str(nIter) 'iter.nii']);
			%
			% 			diffim = abs(im_new-im_old);
			% 			nii = make_nii(abs(diffim),16);
			% 			save_nii(nii,['diff_' num2str(nIter) 'iter.nii']);
			
			% 			reconVol = recon_new;
			
			function y = aFunSNR(x_,transp_flag)
% 				if strcmp(transp_flag,'transp')      % x = A'*y
% 					disp(['Transp, size=' num2str(length(x(:)))]);
% 					y = obj.model.A'*(weights.*obj.dcfObj.dcf.*x);
% 				elseif strcmp(transp_flag,'notransp') % y = A*x
					disp(['NO Transp, size=' num2str(length(x_(:)))]);
					y = (obj.model.A'*(weights.*obj.dcfObj.dcf.*(obj.model.A*x_)));
% 				end
			end
			
			function y = aFunNoSNR(x,transp_flag)
				if strcmp(transp_flag,'transp')      % x = A'*y
					y = (obj.model.A'*x);
				elseif strcmp(transp_flag,'notransp') % y = A*x
					y = (obj.model.A*x);
				end
			end
			
		end
		
		function true_false = isCompatible(obj,model,dcf_iter)
			% Ask if super constructor is compatible
			true_false = (obj.isCompatible@Recon(model));
			
			if(~obj.settings.isCompatible(dcf_iter))
				true_false = false;
			end
		end
	end
end
