function [outputIm tripleOut] = getData(file,  outLat, outLon, distance1, resolution, thisVar)


lon_dd = ncread(file, '/navigation_data/longitude'); lon_dd = lon_dd(:);
lat_dd = ncread(file, '/navigation_data/latitude'); lat_dd = lat_dd(:);
inVar = ncread(file, thisVar); inVar = inVar(:);

zone = utmzone(outLat,outLon);

utmstruct = defaultm('utm');
utmstruct.zone = zone;
utmstruct.geoid = wgs84Ellipsoid; %almanac('earth','grs80','meters');
utmstruct = defaultm(utmstruct);


[centerX, centerY] = mfwdtran( utmstruct, outLat,outLon);

%Define the projected coordinate ROI
e = centerX + distance1;w = centerX - distance1;
n = centerY + distance1;s = centerY - distance1;

%Determine output shape, normalise the projected data so each output pixel
%is of length 1 and starts at 0.
destShape = [round(abs(e - w) /double(resolution)); round(abs(n - s) / double(resolution))];
aff = affine2d([resolution 0.0 w; 0.0 -resolution n; 0 0 1]');


%Define the projected coordianate 2*ROI that's double the size (to retain
%data)
e2 = centerX + distance1*1.2;w2 = centerX - distance1*1.2;
n2 = centerY + distance1*1.2;s2 = centerY - distance1*1.2;

%Inverse trans ROI to get max and min lat and lon
indROI1 = getMinMaxLatLon(e, w, n, s, lon_dd, lat_dd, utmstruct);
%Inverse trans ROI*2 to get max and min lat and lon
indROI2 = getMinMaxLatLon(e2, w2, n2, s2, lon_dd, lat_dd, utmstruct);

%Get all the lat and lon data points within 2*ROI then project back
lon_ddROI1 = lon_dd(indROI1);
lat_ddROI1 = lat_dd(indROI1);
inVarROI1 = inVar(indROI1);
indROI3 = ~isnan(inVarROI1);
lon_ddROI3 = lon_ddROI1(indROI3);
lat_ddROI3 = lat_ddROI1(indROI3);
inVarROI3 = inVarROI1(indROI3);
[lon_projROI3,lat_projROI3] = mfwdtran( utmstruct, lat_ddROI3,lon_ddROI3);
[destIds1,destIds2] = transformPointsInverse(aff,lon_projROI3,lat_projROI3);

tripleOut = [destIds1 destIds2 inVarROI3];
%Get all the lat and lon data points within 2*ROI then project back
lon_ddROI2 = lon_dd(indROI2);
lat_ddROI2 = lat_dd(indROI2);
inVarROI2 = inVar(indROI2);


[lon_projROI, lat_projROI] = mfwdtran(utmstruct,lat_ddROI2,lon_ddROI2);


[destIds1,destIds2] = transformPointsInverse(aff,lon_projROI,lat_projROI);

% Define bin centers.  Must leave a center outside the ROI to mop up the
% values outside the ROI
XbnCntrs = -0.5:destShape(1)+0.5;
YbnCntrs = -0.5:destShape(2)+0.5;

% Count number of datapoints in bins.  Then accumulate their values
cnt = hist3([destIds1, destIds2], {XbnCntrs YbnCntrs});
weightsH = hist2w([destIds1, destIds2], inVarROI2,XbnCntrs,YbnCntrs);

% We must then reduce the size of the output to get rid of the edge bins
weightsH = weightsH(2:end-1,2:end-1);
cnt = cnt(2:end-1,2:end-1);

%If cnt is 0 then no datapoints in bin
%If weightsH is NaN then no datapoint 
%Normalise output and set no data to -1 (for tensorflow etc.)
ign = ((cnt==0)|(isnan(weightsH)));
outputIm = weightsH./cnt;

outputIm(ign) = 0;
outputIm = outputIm';


function indROI = getMinMaxLatLon(e2, w2, n2, s2, lon_dd, lat_dd, utmstruct)

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

indROI = (lon_dd>=minLon)&(lon_dd<=maxLon)&(lat_dd>=minLat)&(lat_dd<=maxLat);










