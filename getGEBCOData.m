function [outputIm tripleOut] = getGEBCOData(config,  outLat, outLon)

%config: H5 file containing gebco bathymetry
%outLat: latitude centre of the HAB
%outLon: longitude centre of the HAB
%distance1: Distance (in meters left and right and up and down from the HAB
%centre
%resolution: Bin size (in meters) of the outputIm
%If the bathymetry is greater than 0 (ie its on land) then return -1 for
%both

distance1 = config.distance1;
resolution = config.resolution;

lon1D = ncread(config.gebcoFilename, '/lon'); 
lat1D = ncread(config.gebcoFilename, '/lat'); 
%inVar = ncread(config.gebcoFilename, '/elevation'); 

zone = utmzone(outLat,outLon);
utmstruct = defaultm('utm');
utmstruct.zone = zone;
utmstruct.geoid = wgs84Ellipsoid; %almanac('earth','grs80','meters');
utmstruct = defaultm(utmstruct);

[centerX, centerY] = mfwdtran( utmstruct, outLat,outLon);

%Define the projected coordinate ROI
e = centerX + distance1; w = centerX - distance1;
n = centerY + distance1; s = centerY - distance1;

%is of length 1 and starts at 0.
destShape = [round(abs(e - w) /double(resolution)); round(abs(n - s) / double(resolution))];
aff = affine2d([resolution 0.0 w; 0.0 resolution s; 0 0 1]');

%Define the projected coordianate 2*ROI that's double the size (to retain
%data)
e2 = centerX + distance1*2;w2 = centerX - distance1*2;
n2 = centerY + distance1*2;s2 = centerY - distance1*2;

%Inverse trans ROI to get max and min lat and lon
[minLon maxLon maxLat minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct);

wholeWidth = length(lon1D);
wholeHeight = length(lat1D);


[thislon lonIndx] = getIndx(minLon, maxLon, lon1D);
[thislat latIndx] = getIndx(minLat, maxLat, lat1D);

start_row = min(latIndx);
start_col = min(lonIndx);
height = max(latIndx)-min(latIndx)+1;
width = max(lonIndx)-min(lonIndx)+1;

bathPatch = ncread(config.gebcoFilename, '/elevation', [start_col start_row], [width height]);
bathPatch = bathPatch';
%Determine output shape, normalise the projected data so each output pixel
[meshlon meshlat] = meshgrid(thislon, thislat);
meshlon = meshlon(:); meshlat=meshlat(:); bathPatch = bathPatch(:);

%Inverse trans ROI*2 to get max and min lat and lon
indROI = getMinMaxLatLonROI(e, w, n, s, meshlon, meshlat, utmstruct);

%Get all the lat and lon data points within 2*ROI then project back
lon_ddROI1 = meshlon(indROI);
lat_ddROI1 = meshlat(indROI);
inVarROI1 = bathPatch(indROI);

[lon_projROI3,lat_projROI3] = mfwdtran( utmstruct, lat_ddROI1,lon_ddROI1);
[destIds1,destIds2] = transformPointsInverse(aff,lon_projROI3,lat_projROI3);

tripleOut = [destIds1 destIds2 inVarROI1];

[lon_projROI3,lat_projROI3] = mfwdtran(utmstruct, meshlat,meshlon);
[destIds1,destIds2] = transformPointsInverse(aff,lon_projROI3,lat_projROI3);

% Define bin centers.  Must leave a center outside the ROI to mop up the
% values outside the ROI
XbnCntrs = -0.5:destShape(1)+0.5;
YbnCntrs = -0.5:destShape(2)+0.5;

% Count number of datapoints in bins.  Then accumulate their values
cnt = hist3([destIds2, destIds1], {YbnCntrs XbnCntrs});
weightsH = hist2w([destIds2, destIds1], bathPatch,YbnCntrs,XbnCntrs);

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
[minLon maxLon maxLat minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct);
indROI = (lon_dd>=minLon)&(lon_dd<=maxLon)&(lat_dd>=minLat)&(lat_dd<=maxLat);

function [minLon maxLon maxLat minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct)
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
thisIndx = (lonlat1D>=minlonlat) & (lonlat1D<maxlonlat);
lonlatIndx = 1:length(lonlat1D);
lonlatIndx = lonlatIndx(thisIndx);
thislatlon = lonlat1D(thisIndx);










