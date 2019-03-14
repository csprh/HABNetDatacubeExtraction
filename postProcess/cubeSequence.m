function cubeSequence
%% This Code loops through al the h5 output files and generates
%% A directory of images in a folder for ingress into Machine Learning model
% Datapoints (lines in the ground truth file) are discounted if they do not
% Contain enough data.
% This file will need to be run twice.  Once to get the range (max and min)
% and once to output the final data images
%
% USAGE:
%   cubeSequence
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill 2nd October 2018
clear; close all;
addpath('..');
[~, tmpStruct] = getHABConfig;

 
cubesDir = tmpStruct.confgData.outDir.Text;
imsDir = tmpStruct.confgData.imsDir.Text
resolution = str2num(tmpStruct.confgData.resolution.Text);
distance1 = str2num(tmpStruct.confgData.distance1.Text);
outputRes = str2num(tmpStruct.confgData.outputRes.Text);
alphaSize = str2num(tmpStruct.confgData.alphaSize.Text);
threshCentrePoint = str2double(tmpStruct.confgData.threshCentrePoint.Text);
threshAll = str2double(tmpStruct.confgData.threshAll.Text);
preLoadMinMax = str2num(tmpStruct.confgData.preLoadMinMax.Text);
numberOfDaysInPast  = str2num(tmpStruct.confgData.numberOfDaysInPast.Text);


%The input range is 50 by 50 samples (in projected space)
%The output resolution is 1000m (1km)
%AlphaSize controls the interpolation projected points to output image

inputRangeX = [0 distance1/resolution];
inputRangeY = [0 distance1/resolution];


h5files=dir([cubesDir '*.h5.gz']);
numberOfH5s=size(h5files,1);

totalDiscount = 0;  %Number of discounted datapoints

if preLoadMinMax ~= 1
    [thisMax, thisMin] = getMinMaxFromH5s(cubesDir);
    groupMinMax = getMinMax(thisMax, thisMin);
    groupMinMax(1,2)  = 0;    %Gebco Bathymetry max (discount land)
    groupMinMax(1,1)  = -380; %Gebco Bathymetry min (discount anything under 500m depth)
    save groupMaxAndMin groupMinMax
else
    load groupMaxAndMin %load the max and minima of the mods
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop through all the ground truth entries%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1: numberOfH5s
    ii
    try
        %% Process input h5 file
        system(['rm ' cubesDir '*.h5']);
        gzh5name = [cubesDir h5files(ii).name];
        gunzip(gzh5name);
        h5name = gzh5name(1:end-3);
        thisCount = h5readatt(h5name,'/GroundTruth/','thisCount');
        [ 'thisCount = ' num2str(thisCount) ];
        isHAB  = thisCount > 0;
        thisH5Info = h5info(h5name);
        thisH5Groups = thisH5Info.Groups;

        % Loop through all groups (apart from GEBCO) and discount
        groupIndex = 3;  %Just choose one.  This should reflect typical sizes
        theseIms = h5read(h5name, [thisH5Groups(groupIndex).Name '/Ims']);
        
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
        baseDirectory = [ imsDir num2str(isHAB) '/' num2str(ii)] ;
        
        outputImagesFromDataCube(baseDirectory,  numberOfDaysInPast, groupMinMax, inputRangeX, inputRangeY, alphaSize, outputRes, h5name);
        
        clear totNumberCP zNumberCP quotCP totNumber zNumber quot
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end


function groupMinMax = getMinMax(thisMax, thisMin)
% USAGE:
%   groupMinMax = getMinMax(thisMax, thisMin)
% INPUT:
%   thisMax = array of maxima
%   thisMin = array of minima
% OUTPUT:
%   groupMinMax = group together the minimum and maximum of input min and max
groupMinMax = [ min(thisMin') ; max(thisMax')]';


