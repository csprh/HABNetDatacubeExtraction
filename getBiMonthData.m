function [outputIm, tripleOut, tripleOutProj ] = getBiMonthData(thisDay, config,  outLat, outLon, utmstruct)
% Extract binned image and value triplet array from BiMonthly H5 files
%
% USAGE:
%   [outputIm, tripleOut, tripleOutProj ] = getBiMonthData(thisDay, config,  outLat, outLon, utmstruct)
% INPUT:
%   thisDay - the day the datacube is to be created
%   config - input configuration
%     confgData.biDir: Directory containing bimonth H5 files
%   outLat - latitude centre of the HAB
%   outLon - longitude centre of the HAB
%   utmstruct - projection def

% OUTPUT:
%   outputIm - Image of the biMonth data at the resolution defined in config
%   tripleOut - x,y and biMonth data triplet  output
%   tripleOutProj - projected x,y and biMonth data output
%
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill 26th June 2019

biDir = confgData.biDir;
biMonthlyOffset = 61;
thisDay = thisDay -14;

h5name = [biDir '/Bimonthly_Chlor_a_' num2str(thisDay-biMonthlyOffset) '_' num2str(thisDay) '.h5'];


biChlor = h5read(h5name,'/Chlor_a');
lon1D = h5read(h5name, '/lon');
lat1D = h5read(h5name, '/lat');

lon1D = lon1D(:);
lat1D = lat1D(:);

biChlor = biChlor(:);

distance1 = config.distance1;
resolution = config.resolution;

 

%Define the projected coordinate ROI
[centerX, centerY] = mfwdtran( utmstruct, outLat,outLon);
e = centerX + distance1; w = centerX - distance1;
n = centerY + distance1; s = centerY - distance1;

%is of length 1 and starts at 0.
destShape = [round(abs(e - w) /double(resolution)); round(abs(n - s) / double(resolution))];
aff = affine2d([resolution 0.0 w; 0.0 resolution s; 0 0 1]');

%Define the projected coordianate 2*ROI that's double the size (to retain
%data)
e2 = centerX + distance1*2; w2 = centerX - distance1*2;
n2 = centerY + distance1*2; s2 = centerY - distance1*2;

%Inverse trans ROI to get max and min lat and lon
[minLon, maxLon, maxLat, minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct);
[thislon, lonIndx] = getIndx(minLon, maxLon, lon1D);
[thislat, latIndx] = getIndx(minLat, maxLat, lat1D);


%Determine output shape, normalise the projected data so each output pixel
[meshlon, meshlat] = meshgrid(thislon, thislat);
meshlon = meshlon(:); meshlat=meshlat(:); 

%Inverse trans ROI*2 to get max and min lat and lon
indROI = getMinMaxLatLonROI(e, w, n, s, meshlon, meshlat, utmstruct);

%Get all the lat and lon data points within 2*ROI then project back
lon_ddROI1 = meshlon(indROI);
lat_ddROI1 = meshlat(indROI);
inVarROI1 = biChlor(indROI);

[lon_projROI2,lat_projROI2] = mfwdtran( utmstruct, lat_ddROI1,lon_ddROI1);
[destIds1,destIds2] = transformPointsInverse(aff,lon_projROI2,lat_projROI2);

tripleOut =     [lon_ddROI1 lat_ddROI1 inVarROI1];
tripleOutProj = [destIds1 destIds2 inVarROI1];

[lon_projROI3,lat_projROI3] = mfwdtran(utmstruct, meshlat,meshlon);
[destIds1,destIds2] = transformPointsInverse(aff,lon_projROI3,lat_projROI3);

% Define bin centers.  Must leave a center outside the ROI to mop up the
% values outside the ROI
XbnCntrs = -0.5:destShape(1)+0.5;
YbnCntrs = -0.5:destShape(2)+0.5;

% Count number of datapoints in bins.  Then accumulate their values
cnt = hist3([destIds2, destIds1], {YbnCntrs XbnCntrs});
weightsH = hist2w([destIds2, destIds1], biChlor,YbnCntrs,XbnCntrs);

% We must then reduce the size of the output to get rid of the edge bins
weightsH = weightsH(2:end-1,2:end-1);
cnt = cnt(2:end-1,2:end-1);

%If cnt is 0 then no datapoints in bin
%If weightsH is NaN then no datapoint 
%Normalise output and set no data to -1 (for tensorflow etc.)
ign = ((cnt==0)|(isnan(weightsH)));
outputIm = weightsH./cnt;

outputIm(ign) = 0;


function indROI = getMinMaxLatLonROI(e2, w2, n2, s2, lon_dd, lat_dd, utmstruct)
% Generate Region of Interest (ROI) index from input parameters
%
% USAGE:
%   indROI = getMinMaxLatLon(e2, w2, n2, s2, lon_dd, lat_dd, utmstruct)
% INPUT:
%   e2 - minimum east
%   w2 - maximum west
%   n2 - minimum north
%   s2 - maximum south
%   lon_dd - input lattitude index array
%   lat_dd - input longitude index array
%   utmstruct - reprojection definition
% OUTPUT:
%   indROI - index output
[minLon maxLon maxLat minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct);
indROI = (lon_dd>=minLon)&(lon_dd<=maxLon)&(lat_dd>=minLat)&(lat_dd<=maxLat);

function [minLon maxLon maxLat minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct)
% Obtain min and max lat and lon of ROI
%
% USAGE:
%   [minLon maxLon maxLat minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct)
% INPUT:
%   e2 - minimum east
%   w2 - maximum west
%   n2 - minimum north
%   s2 - maximum south
%   utmstruct - reprojection definition
% OUTPUT:
%   minLon - minimum lon
%   maxLon - maximum lon
%   minLat - minimum lat
%   maxLat - maximum lat

tl = [w2 n2]; bl = [w2 s2];
tr = [e2 n2]; br = [e2 s2];
[tlLat, tlLon] = minvtran(utmstruct, tl(1), tl(2));
[blLat, blLon] = minvtran(utmstruct, bl(1), bl(2));
[trLat, trLon] = minvtran(utmstruct, tr(1), tr(2));
[brLat, brLon] = minvtran(utmstruct, br(1), br(2));
minLon = min([tlLon blLon trLon brLon]);
maxLon = max([tlLon blLon trLon brLon]);
minLat = min([tlLat blLat trLat brLat]);
maxLat = max([tlLat blLat trLat brLat]);


function [thislatlon, lonlatIndx] = getIndx(minlonlat, maxlonlat, lonlat1D)
thisIndx = (lonlat1D>=minlonlat) & (lonlat1D<=maxlonlat);
lonlatIndx = 1:length(lonlat1D);
lonlatIndx = lonlatIndx(thisIndx);
thislatlon = lonlat1D(thisIndx);










