function land = isLandGEBCO(inStruc, config, thisThresh)
% Input lat and lon (defined in inStruc), output if is land (bathymetry > 10m)
%
% USAGE:
%   isLandGEBCO(inStruc, config, thisThresh)
% INPUT:
%   inStruc - contains lat and lon
%   config - contains gebcoFilename of gebco netCDF file
%   thisThresh - optional threshold.  Default = 10m
% OUTPUT:
%   land - boolean is land variable

if nargin < 3
    thisThresh = 10;
end

outLat = inStruc.thisLat;
outLon = inStruc.thisLon;
        
lon1D = ncread(config.gebcoFilename, '/lon'); 
lat1D = ncread(config.gebcoFilename, '/lat'); 

[~, centre_col] = min(abs(lon1D-outLon));
[~, centre_row] = min(abs(lat1D-outLat));
bathAt = ncread(config.gebcoFilename, '/elevation', [centre_col centre_row], [1 1]);
land = bathAt > thisThresh; % if the bathymetry is greater than 10m assume that it is land

