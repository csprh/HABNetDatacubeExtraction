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


if ismac
    filenameBase1 = '/Users/csprh/tmp/florida2/';
    filenameBase2 = '/Users/csprh/tmp/CNNIms/florida2/';
else
    filenameBase1 = '/mnt/storage/home/csprh/scratch/HAB/florida4/';
    filenameBase2 = '/mnt/storage/home/csprh/scratch/HAB/CNNIms/florida4/';
end

trainTestStr = {'Test','Train'};

h5files=dir([filenameBase1 '*.h5.gz']);
numberOfH5s=size(h5files,1); 

totalDiscount = 0;  %Number of discounted datapoints
minmaxind = 1;

trainTestR = randi([0 1],1,numberOfH5s);

load groupMaxAndMin %load the max and minima of the mods
groupMinMax = getMinMax(thisMax, thisMin);

%%Loop through all the ground truth entries
for ii = 1: numberOfH5s 
    ii
    try 
    system(['rm ' filenameBase1 '*.h5']);
    gzh5name = [filenameBase1 h5files(ii).name];
    gunzip(gzh5name);
	h5name = gzh5name(1:end-3);

    thisCount = h5readatt(h5name,'/GroundTruth/','thisCount');
    [ 'thisCount = ' num2str(thisCount) ]; 
    
    isHAB  = thisCount > 0; 
    thisH5Info = h5info(h5name);
    thisH5Groups = thisH5Info.Groups;
    numberOfGroups = size(thisH5Groups,1);

    dayEnd = h5readatt(h5name,'/GroundTruth/','dayEnd');
    dayStart = h5readatt(h5name,'/GroundTruth/','dayStart');
    numberOfDays = dayEnd - dayStart;
    numberOfDays = 10;
    
    % Loop through all groups (apart from GEBCO) and discount
    groupIndex = 3;  %Just choose one.  This should reflect typical sizes 
    thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
    theseIms = h5read(h5name, [thisGroupName{groupIndex} '/Ims']);
    
    numberOfIms = size(theseIms,3);
    
    %% Loop through saved images.  There may be a variable number of images
    %  The amount of data as a quotiant is the calculated (for whole image
    %  and a central patch)
    %  It the quotiants are less than a threshold then the datapoint is
    %  discounted
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
    allThereCP = (quotCP>0.5);
    allThere = (quot>0.2);
    allThereTotal = [ allThereCP allThere ];
    thisDiscount = (sum(allThereTotal) ~= length(allThereTotal));
   
    % Discount this line in the Ground Truth 
    if thisDiscount == 1
        totalDiscount= totalDiscount+1;
        continue;
    end
    totalDiscount
    
    %Split output into train/test, HAB Class directory, Ground truth line
    %number, Group Index
    baseDirectory = [ filenameBase2 trainTestStr{trainTestR(ii)+1 } '/' num2str(isHAB) '/' ] ;
    
    %%Loop through all modalities 
    for groupIndex = 2: numberOfGroups
        thisGroupIndex = groupIndex-1;
        thisBaseDirectory = [baseDirectory '/', num2str(ii) '/' num2str(thisGroupIndex) '/'];
        mkdir(thisBaseDirectory);
        
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        theseIms = h5read(h5name, [thisGroupName{groupIndex} '/Ims']);
        theseDeltaDates = h5read(h5name, [thisGroupName{groupIndex} '/theseDeltaDates']);
        
         %%Loop through days, quantise them, sum, clip and output
        for thisDay  = 1:numberOfDays
            quantEdge1 = thisDay-1; quantEdge2 = thisDay;
            theseIndices = (theseDeltaDates>=quantEdge1) & (theseDeltaDates<quantEdge2);
            
            if sum(theseIndices)==0
                quantIms = zeros(size(theseIms(:,:,1)));
            else
                quantIms = theseIms(:,:,theseIndices);
            end
            
            quantIms(quantIms==0)=NaN;
            quantIms = nanmean(quantIms, 3);

            thisMax(thisGroupIndex,minmaxind) = max(quantIms(:));
            thisMin(thisGroupIndex,minmaxind) = min(quantIms(:));
            minmaxind = minmaxind + 1;
           
	    % Quantisation Image Scaling and Infill 
            quantIms = quantIms-groupMinMax(thisGroupIndex,1);
            quantIms = 255*(quantIms./(groupMinMax(thisGroupIndex,2)-groupMinMax(thisGroupIndex,1)));
            quantIms(quantIms>255) = 255;
            quantIms(quantIms<0) = 0;
            quantIms(isnan(quantIms))=0;
            quantIms = imfill(quantIms);
            imwrite(uint8(quantIms),[thisBaseDirectory  sprintf('%02d',thisDay),'.jpg'],'Quality',100);

        end
    end
    clear totNumberCP zNumberCP quotCP totNumber zNumber quot 
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end

% Save the max and min for next run
save groupMaxAndMin thisMax thisMin

function groupMinMax = getMinMax(thisMax, thisMin)
% USAGE:
%   groupMinMax = getMinMax(thisMax, thisMin)
% INPUT:
%   thisMax = array of maxima
%   thisMin = array of minima
% OUTPUT:
%   groupMinMax = group together the minimum and maximum of input min and max
groupMinMax = [ min(thisMin') ; max(thisMax')]';

