%SPLITGASDISSOLVED   Splits a dual phase acquisition into gas and dissolved
%   phase images. 
%
%   See also GE_READ_PFILE.
%
%   Copyright: 2013 Scott Haile Robertson.
%   Website: www.ScottHaileRobertson.com
%   $Revision: 1.0 $  $Date: 2013/01/02 $
function [disolved_fid_data, gas_fid_data, header] = splitGasDissolved(varargin)

% Check if pfile is given
if(nargin < 1)
    % Get pfile
    [file, path] = uigetfile('*.*', 'Select Pfile');
    pfile_name = strcat(path, file)
else
    % If pfile name is given, use it.
    pfile_name = varargin{1};
end

% Parameters that almost never change.
hdr_off    = 0;         % Typically there is no offset to the header
byte_order = 'ieee-le'; % Assume little endian format
precision = 'int16';      % Can we read this from header? CSI extended mode uses int32


% Read header
header = ge_read_header(pfile_name, hdr_off, byte_order);
    
% Read pfile data
recon_data = Recon_Data();
recon_data = recon_data.readPfileData(pfile_name,byte_order, precision,header);
recon_data = recon_data.removeBaselines(header);

% Remove junk views, update nframes
junk_views=1; % Not sure why we have an extra junk view, but so it goes...
recon_data.Data(:,1:junk_views)=[];
    
% Split into gas and dissolved images   
disolved_fid_data = Recon_Data();
disolved_fid_data.Data = recon_data.Data(:,1:2:end);
disolved_fid_data.Nframes = size(disolved_fid_data.Data,2);
disolved_fid_data.Npts = recon_data.Npts; 

gas_fid_data = Recon_Data;
gas_fid_data.Data = recon_data.Data(:,2:2:end);
gas_fid_data.Nframes = size(disolved_fid_data.Data,2);
gas_fid_data.Npts = recon_data.Npts;
% Optional save of .rp files (only needed if using radish for recon)
