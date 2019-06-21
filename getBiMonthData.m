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

biDir = config.biDir;
biMonthlyOffset = 61;
thisDay = thisDay -14;

h5name = [biDir '/Bimonthly_Chlor_a_' num2str(thisDay-biMonthlyOffset) '_' num2str(thisDay) '.h5'];


biChlor = h5read(h5name,'/Chlor_a');
lonDD = h5read(h5name, '/lon');
latDD = h5read(h5name, '/lat');

lonDD = lonDD(:);
latDD = latDD(:);

inVar = biChlor(:);
[centerXProj, centerYProj] = mfwdtran( utmstruct, outLat,outLon);

%Define the projected coordinate ROI
eProj = centerXProj + round(distance1/2); wProj = centerXProj - round(distance1/2);
nProj = centerYProj + round(distance1/2); sProj = centerYProj - round(distance1/2);

%Determine output shape, normalise the projected data so each output pixel
%is of length 1 and starts at 0.
destShape = [round(abs(eProj - wProj) /double(resolution)); round(abs(nProj - sProj) / double(resolution))];
aff = affine2d([resolution 0.0 wProj; 0.0 resolution sProj; 0 0 1]');

%Define the projected coordianate 1.2*ROI that's double the size (to retain
%data)
eProj2 = centerXProj + round(distance1/2)*1.2; wProj2 = centerXProj - round(distance1/2)*1.2;
nProj2 = centerYProj + round(distance1/2)*1.2;  sProj2 = centerYProj - round(distance1/2)*1.2;

%Inverse trans ROI to get max and min lat and lon
indROI = getMinMaxLatLon(eProj, wProj, nProj, sProj, lonDD, latDD, utmstruct);

[lonDDROI, latDDROI, inVarROI, destIds1, destIds2] = getProjs(aff,utmstruct, latDD, lonDD, inVar, indROI);  
%Get all the lat and lon data points within ROI then project back

tripleOut = [lonDDROI latDDROI inVarROI];
tripleOutProj = [destIds1 destIds2 inVarROI];

indROI = getMinMaxLatLon(eProj2, wProj2, nProj2, sProj2, lonDD, latDD, utmstruct);
%Inverse trans ROI*1.2 to get max and min lat and lon

%Get all the lat and lon data points within 1.2*ROI then project back
[lonDDROI, latDDROI, inVarROI, destIds1, destIds2] = getProjs(aff,utmstruct, latDD, lonDD, inVar, indROI);  

tripleOut = [lonDDROI latDDROI inVarROI];
tripleOutProj = [destIds1 destIds2 inVarROI];

% Define bin centers.  Must leave a center outside the ROI to mop up the
% values outside the ROI
XbnCntrs = -0.5:destShape(1)+0.5;
YbnCntrs = -0.5:destShape(2)+0.5;

% Count number of datapoints in bins.  Then accumulate their values
cnt = hist3([destIds2, destIds1], {YbnCntrs XbnCntrs});
weightsH = hist2w([destIds2, destIds1], inVarROI ,YbnCntrs,XbnCntrs);

% We must then reduce the size of the output to get rid of the edge bins
weightsH = weightsH(2:end-1,2:end-1);
cnt = cnt(2:end-1,2:end-1);

%If cnt is 0 then no datapoints in bin
%If weightsH is NaN then no datapoint 
%Normalise output and set no data to -1 (for tensorflow etc.)
ign = ((cnt==0)|(isnan(weightsH)));
outputIm = weightsH./cnt;

outputIm(ign) = 0;


function [lonDDROI, latDDROI, inVarROI, destIds1, destIds2] = getProjs(aff, utmstruct, latDD, lonDD, inVar, indROI)  
% Generateregion of interest indices and projected outputs
%
% USAGE:
%   [lonDDROI, latDDROI, inVarROI, destIds1, destIds2] = getProjs(aff, utmstruct, latDD, lonDD, inVar, indROI) 
% INPUT:
%   aff       - forward transform
%   utmstruct - utm projection transform
%   lonDD     - input longitude values
%   latDD     - input latitude values
%   inVar     - actual variable values
%   inROI     - region of interest indexed values
% OUTPUT:
%   lonDDROI  - output lon values
%   latDDROI  - output lat values
%   inVarROI  - output var values
%   destIds1  - transformed positions
%   destIds2  - transformed positions

%Get all the lat and lon data points within ROI then project back
lonDDROI = lonDD(indROI);
latDDROI = latDD(indROI);
inVarROI = inVar(indROI);

%discount any missing datapoints
indROINaN = ~isnan(inVarROI);
lonDDROI = lonDDROI(indROINaN);
latDDROI = latDDROI(indROINaN);
inVarROI = inVarROI(indROINaN);
[lonProjROI,latProjROI] = mfwdtran(utmstruct, latDDROI,lonDDROI);
[destIds1,destIds2] = transformPointsInverse(aff,lonProjROI,latProjROI);


function [minLon, maxLon, maxLat, minLat] = getMinMaxLatLon(e2, w2, n2, s2, utmstruct)
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










