function land = isLandGEBCO(inStruc, config)
% Input lat and lon (defined in inStruc), output if is land (bathymetry > 10m)
%
% USAGE:
%   land = isLandGEBCO(inStruc, config)
% INPUT:
%   inStruc - contains lat and lon
%   config - contains gebcoFilename of gebco netCDF file
% OUTPUT:
%   land - boolean is land variable

outLat = inStruc.thisLat;
outLon = inStruc.thisLon;
        
lon1D = ncread(config.gebcoFilename, '/lon'); 
lat1D = ncread(config.gebcoFilename, '/lat'); 

[dummy centre_col] = min(abs(lon1D-outLon));
[dummy centre_row] = min(abs(lat1D-outLat));
bathAt = ncread(config.gebcoFilename, '/elevation', [centre_col centre_row], [1 1])
land = bathAt > 10; % if the bathymetry is greater than 10m assume that it is land

