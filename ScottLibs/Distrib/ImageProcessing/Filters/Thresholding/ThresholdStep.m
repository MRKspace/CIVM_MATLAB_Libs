%IMAGEPROCESSINGSTEP
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/04/04 $
classdef ThresholdStep < ImageProcessingStep
    properties
        Threshold;
        Direction;
    end
    
    methods
        function this = ThresholdStep(varargin)
            % Load input parameters
            if(nargin > 0)
                this.Threshold = varargin{1};
                if(nargin > 1)
                    this.Direction = varargin{2};
                end
            end
        end
        
        function [output_vol] = process(this, vol)
            % if no threshold given, display GUI
            if(isempty(this.Threshold))
                this.Threshold = displayThresholdGUI(this, vol);
            end
            
            % Threshold data
            switch this.Direction
                case 'gt'
                    output_vol = Volume(vol.Data > this.Threshold);
                case 'lt'
                    output_vol = Volume(vol.Data < this.Threshold);
                otherwise
                    output_vol = Volume(ones(vol.Dims));
            end
        end
        
        function displayThresholdGUI(this, vol)
            handle = showSlices(vol);
            
            roipoly(handle);
        end
    end
end