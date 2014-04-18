%MANUALSEGMENTATIONSTEP
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/04/04 $
classdef ManualSegmentationStep < ImageProcessingStep
    properties
        Mask;
    end
    
    methods
        function this = ManualSegmentationStep(varargin)
            if(nargin > 0)
                this.Mask = varargin{1};
            end
        end
        
        function [output_vol] = process(this, vol)
            if(isempty(this.Mask))
                displayManualSegmentationGUI(this, vol);
            end
            
            output_vol = this.Mask;
        end
        
        function displayManualSegmentationGUI(this, vol)
            figure();
            fig_handle = showSlices(vol.Data);
            
            fig_data = guidata(fig_handle);
            poly_shape = impoly(fig_data.plot_axes);
            
            this.Mask = createMask(poly_shape,fig_data.hImage);
        end
    end
end