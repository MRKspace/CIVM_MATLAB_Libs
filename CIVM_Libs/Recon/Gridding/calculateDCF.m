function dcf = calculateDCF(recon_data, header, dcf_type, ...
    overgridfactor, kernel_width, output_dims, im_sz_dcf, ...
    numIter,saveDCF_dir)

if(dcf_type == 1)
    dcf = calcDCF_Analytical(recon_data, header);
elseif(dcf_type == 2)
    dcf = dcf_hitplane_mex(recon_data.Traj, overgridfactor*kernel_width, overgridfactor*output_dims);
else
    if( (dcf_type == 3) || (dcf_type == 5) )
        dcf_filename = [saveDCF_dir 'VoronoiDCF_kernWidth' ...
            num2str(overgridfactor*kernel_width) '_matrixSize' ...
            num2str(overgridfactor*output_dims(1)) '.mat'];
        if(exist(dcf_filename))
            load(dcf_filename);
        else
            dcf = calcDCF_Voronoi(recon_data, header);
            save(dcf_filename,'dcf');
        end
    end
    
    if(dcf_type == 4)
        dcf_filename = [saveDCF_dir 'ItterativeDCF_overgrid' ...
            num2str(overgridfactor) '_imSize' ...
            num2str(im_sz_dcf) '_numItt' num2str(numIter) '.mat'];
        if(exist(dcf_filename))
            load(dcf_filename);
        else
            dcf = calcDCF_Itterative(recon_data.Traj, overgridfactor,im_sz_dcf,numIter);
            save(dcf_filename,'dcf');
        end
    elseif(dcf_type == 5)
        dcf_filename = [saveDCF_dir 'VoronoiItterativeDCF_overgrid' ...
            num2str(overgridfactor) '_imSize' ...
            num2str(im_sz_dcf) '_numItt' num2str(numIter) '.mat'];
        if(exist(dcf_filename))
            load(dcf_filename);
        else
            dcf = calcDCF_Itterative(recon_data.Traj,overgridfactor,im_sz_dcf,numIter,dcf);
            save(dcf_filename,'dcf');
        end
    end
end
end %function