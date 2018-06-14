function getDataOuter;
clear; close all;

if ismac
    filenameBase = '~/Dlaptop/MATLAB/MYCODE/HAB/WORK/HAB/florida1/';
else
    filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida1/';
end
outPutHAB = [filenameBase 'cnnData/1/'];
outPutNoHAB = [filenameBase 'cnnData/0/'];
numberOfH5s = 9;

allMin = 100000; allMax = 0; 
HAB = 0;
NoHAB = 0;
thisInd = 1;
for ii = 1: numberOfH5s %Loop through all the ground truth entries
    gzh5name = [filenameBase 'flor' num2str(ii) '.h5.gz'];
    gunzip(gzh5name);
	h5name = [filenameBase 'flor' num2str(ii) '.h5'];
	
	%h5disp(h5name);
	try

    thisCount= h5read(h5name,'/thisCount');
    thisH5Info = h5info(h5name);
    thisH5Groups = thisH5Info.Groups;
    numberOfGroups = size(thisH5Groups,1);
    for groupIndex = 1: numberOfGroups
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        Ims{groupIndex}= h5read(h5name, [thisGroupName{groupIndex} '/Ims']);
    end
    isHAB(thisInd) = thisCount >0;
    theseImages = cat(3,Ims{7},Ims{14});
    theseImages(theseImages==0)=NaN;
     
    thisImage = nanmean(theseImages,3);
    fullNumber = prod(size(thisImage));
    nanNumber = sum(isnan(thisImage(:)));
    
    thisRatio = nanNumber / fullNumber;
    if thisRatio > 0.8
        continue;
    end
    thisMax(thisInd) = max(thisImage(:));
    thisMin(thisInd) = min(thisImage(:));
    thisImage(thisImage==NaN)=0;
    thisImage = round(thisImage*(255/466.5));
    if isHAB(thisInd)==0
        imwrite(uint8(thisImage),[outPutNoHAB num2str(NoHAB) '.jpg']);
        NoHAB = NoHAB +1;
    else
        imwrite(uint8(thisImage),[outPutHAB num2str(HAB) '.jpg']);
        HAB = HAB +1;
    end
    thisInd = thisInd + 1;
    ['thisInd = ' num2str(thisInd) ' max = ' num2str(max(thisMax))]
    [ 'min = '    num2str(min(thisMin))]
    catch
    end
end
allMax

function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1 
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
