function BPandSS
%% This Code loops through all the h5 output files and generates HAB flags using 
%% 

% USAGE:
%   BPandSS;
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill Nov 2019
clear; close all;
addpath('..');
[rmcommand, ~, tmpStruct] = getHABConfig;


cubesDir = tmpStruct.confgData.trainDir.Text;
imsDir = tmpStruct.confgData.trainImsDir.Text;
resolution = str2num(tmpStruct.confgData.resolution.Text);
distance1 = str2num(tmpStruct.confgData.distance1.Text);

threshCentrePoint = str2double(tmpStruct.confgData.threshCentrePoint.Text);
threshAll = str2double(tmpStruct.confgData.threshAll.Text);

%The input range is usually 50 by 50 samples (in projected space)
%The output resolution is 1000m (1km).  This results in 100x100 pixels images
%AlphaSize controls the interpolation projected points to output image

inputRangeX = [0 distance1/resolution];
inputRangeY = [0 distance1/resolution];


h5files=dir([cubesDir '*.h5.gz']);
numberOfH5s=size(h5files,1);

totalDiscount = 0;  %Number of discounted datapoints


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop through all the ground truth entries%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
indOut = 1;
for ii = 1: numberOfH5s
    
    try
        %% Process input h5 file
        system([rmcommand cubesDir '*.h5']);
        gzh5name = [cubesDir h5files(ii).name];
        gunzip(gzh5name);
        h5name = gzh5name(1:end-3);
        thisCount = h5readatt(h5name,'/GroundTruth/','thisCount');
        
        [ 'thisCount = ' num2str(thisCount) ];
        isHAB  = thisCount > 0;
        thisH5Info = h5info(h5name);
        
        % Loop through all groups (apart from GEBCO) and discount
        %Just choose one.  This should reflect typical sizes
        theseIms = h5read(h5name, '/oc-modisa-chlor_a/Ims');
        
        numberOfIms = size(theseIms,3);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Loop through saved images.  There may be a variable number of images
        %% The amount of data as a quotiant is the calculated (for whole image
        %% and a central patch)
        %% It the quotiants are less than a threshold then the datapoint is
        %% discounted
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for iii = 1:numberOfIms
            thisIm = theseIms(:,:,iii);
            centrePatchP = size(thisIm)/2+2;
            centrePatchM = size(thisIm)/2-1;
            centrePatch = thisIm(centrePatchM(1):centrePatchP(:),centrePatchM(2):centrePatchP(2));
            
            totNumberCP(iii) = prod(size(centrePatch));
            zNumberCP(iii) = sum(centrePatch(:)==0);
            quotCP(iii) = zNumberCP(iii) / totNumberCP(iii);
            
            totNumber(iii) = prod(size(theseIms));
            zNumber(iii) = sum(theseIms(:)==0);
            quot(iii) = zNumber(iii) / totNumber(iii);
        end
        
        allThereCP = (quotCP>threshCentrePoint);
        allThere = (quot>threshAll);
        allThereTotal = [ allThereCP allThere ];
        thisDiscount = (sum(allThereTotal) ~= length(allThereTotal));
        
        % Discount this line in the Ground Truth
        if thisDiscount == 1
            totalDiscount= totalDiscount+1;
            totalDiscount
            continue;
        end
        
        %Split output into train/test, HAB Class directory, Ground truth line
        %number, Group Index
        baseDirectory = [ imsDir filesep num2str(isHAB) '/' num2str(ii)] ;
  
        [isHABSS, isHABBP] = getBBANDSSFromDataCube(h5name, inputRangeX, inputRangeY);
        
        isHABOut(indOut,:) = [isHAB isHABSS isHABBP];
        indOut = indOut+1;
        clear totNumberCP zNumberCP quotCP totNumber zNumber quot
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end
save isHABOut isHABOut

function [isHABSS, isHABBP] = getBBANDSSFromDataCube(h5name, inputRangeX, inputRangeY)


cvChl = getCentralPoint(h5read(h5name, ['/oc-modisa-chlor_a/PointsProj']), inputRangeX, inputRangeY);
cv443 = getCentralPoint(h5read(h5name, ['/oc-modisa-Rrs_443/PointsProj']), inputRangeX, inputRangeY);
cv488 = getCentralPoint(h5read(h5name, ['/oc-modisa-Rrs_488/PointsProj']), inputRangeX, inputRangeY);
cv531 = getCentralPoint(h5read(h5name, ['/oc-modisa-Rrs_531/PointsProj']), inputRangeX, inputRangeY);
cv555 = getCentralPoint(h5read(h5name, ['/oc-modisa-Rrs_555/PointsProj']), inputRangeX, inputRangeY);

bp555 = -0.00182+2.058*cv555;
bp555Morel = 0.3*(cvChl^0.62)*(0.002+0.02*(0.5-0.25*log10(cvChl)));
bpQuotient = bp555/bp555Morel;
isHABBP = bpQuotient > 1.0;

SSLambda = cv488 - cv443 - (cv531 - cv443)*((cv488 - cv443)/(cv531 - cv443));
isHABSS = SSLambda < 0.0;

function centralValueDay0 = getCentralPoint(PointsProj, inputRangeX, inputRangeY)

midX = mean(inputRangeX);
midY = mean(inputRangeY);

zp = PointsProj(:,4);
theseIndices = (zp>=0) & (zp<1);

xp = PointsProj(theseIndices,1);
yp = PointsProj(theseIndices,2);
valp = PointsProj(theseIndices,3);

distToCentre = sqrt((xp-midX).^2+(yp-midY).^2);
[~, indMin] = min(distToCentre);
centralValueDay0 = valp(indMin);



