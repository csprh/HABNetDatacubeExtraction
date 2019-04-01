function  [latitude, longitude] =  getLatLonArray(gulf, deltaran)
%% Top level code that loads xml config, then it loads gebco
%% Then it looks through the limits of the lat and lon ranges
%% discounting the points on the land
%
% USAGE:
%   getLatLonArray;
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019 PRH


[rmcommand, pythonStr, tmpStruct] = getHABConfig;


load(tmpStruct.confgData.inputFilename.Text);
%% load all config from XML file
confgData.gebcoFilename = tmpStruct.confgData.gebcoFilename.Text;


if gulf
    latrang = [23 30.42]; lonrang = [47.69 58]; %Gulf
    matString = ['Gulf_' num2str(thisDate)];
else
    latrang = [24.0864 30.8012]; lonrang = [-88.0453 -79.8748]; %Florida
    matString = ['Florida_' num2str(thisDate)];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Loop through ramge of lat and lon                  %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ind = 1 ;

for thisLat = latrang(1):deltaran:latrang(2)
    for thisLon = lonrang(1):deltaran:lonrang(2)
        inStruc.ii = 0;
        inStruc.thisLat = thisLat;
        inStruc.thisLon = thisLon;
        
        if isLandGEBCO(inStruc, confgData);  continue;  end;
        latitude(ind) = thisLat;
        longitude(ind) = thisLon;
        sample_date(ind) = thisDate;
        count2(ind) = 0 ;

        ind = ind + 1;
    end
end

%geoshow(latitude,longitude,'displaytype','point')
%save (matString, 'latitude', 'longitude', 'sample_date', 'count2');
