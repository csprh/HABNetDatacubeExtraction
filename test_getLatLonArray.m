function  [latitude, longitude] =  test_getLatLonArray(gulf, deltaran, optHeight)
%% get lat/lon arrays for either florida or the gulf area
%% Then it looks through the limits of the lat and lon ranges
%% discounting the points on the land
%
% USAGE:
%   [latitude, longitude] =  getLatLonArray(gulf, deltaran, optHeight)
% INPUT:
%   gulf: 1 if the gult, florida if not
%   deltaran:  deltaRange
%   optHeight: optional height
% OUTPUT:
%   latitude: array of latitude points (in the sea)
%   longitude: array of longitude points (in the sea)

% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019 PRH

if nargin < 3
    optHeight = 0;
end
[~, ~, tmpStruct] = getHABConfig;

%% load all config from XML file
confgData.gebcoFilename = tmpStruct.confgData.gebcoFilename.Text;

if gulf
    latrang = [23 30.42]; lonrang = [47.69 58]; %Gulf
else
    latrang = [24.0864 30.8012]; lonrang = [-88.0453 -79.8748]; %Florida
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
        
        if isLandGEBCO(inStruc, confgData, optHeight);  continue;  end;
        latitude(ind) = thisLat;
        longitude(ind) = thisLon;
        ind = ind + 1;
    end
end

