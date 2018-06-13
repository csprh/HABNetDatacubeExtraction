function land = isLandGEBCO(inStruc, config)

%config: H5 file containing gebco bathymetry
%If the bathymetry is greater than 0 (ie its on land) then return -1 for
%both
outLat = inStruc.thisLat;
outLon = inStruc.thisLon;
        
lon1D = ncread(config.gebcoFilename, '/lon'); 
lat1D = ncread(config.gebcoFilename, '/lat'); 

[dummy centre_col] = min(abs(lon1D-outLon));
[dummy centre_row] = min(abs(lat1D-outLat));
bathAt = ncread(config.gebcoFilename, '/elevation', [centre_col centre_row], [1 1])
land = bathAt > 10; % if the bathymetry is greater than 10m assume that it is land

