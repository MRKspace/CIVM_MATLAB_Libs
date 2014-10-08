%IMAGEPROCESSINGSTEP
%
%   Copyright: 2012 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2012/04/04 $
classdef ImageProcessingStep 
    methods(Abstract = true)
        [output_vol this] = process(this, volume)
    end
end