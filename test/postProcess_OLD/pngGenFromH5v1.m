function getDataOuter;
clear; close all;

filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida1';
outPutHAB = [filenameBase 'cnnData/1/'];
outPutNoHAB = [filenameBase 'cnnData/0/'];
numberOfH5s = 2650;

allMin = 100000; allMax = 0; 
HAB = 0;
NoHAB = 0;
for ii = 1: numberOfH5s %Loop through all the ground truth entries
	h5name = [filenameBase 'flor' num2str(ii) '.h5'];
	%h5disp(h5name);
    thisCount= h5read(h5name,'/thisCount');
    isHAB(ii) = thisCount >0;
	theseImages = h5read(h5name,'/chlor_a/Ims');
    theseImages(theseImages==0)=NaN;
    
    thisImage = nanmean(theseImages,3);
    thisImage(thisImage==NaN)=0;
    thisImage = round(thisImage*(255/464.1867));
    thisMax(ii) = max(thisImage(:));
    thisMin(ii) = min(thisImage(:)); 
    if isHAB(ii)==0
        imwrite(uint8(thisImage),[outPutNoHAB num2str(NoHAB) '.jpg']);
        NoHAB = NoHAB +1;
        imwrite(uint8(flipud(thisImage)),[outPutNoHAB num2str(NoHAB) '.jpg']);
        NoHAB = NoHAB +1;
        imwrite(uint8(fliplr(thisImage)),[outPutNoHAB num2str(NoHAB) '.jpg']);
        NoHAB = NoHAB +1;
        imwrite(uint8(fliplr(flipud(thisImage))),[outPutNoHAB num2str(NoHAB) '.jpg']);
        NoHAB = NoHAB +1;
    else
        imwrite(uint8(thisImage),[outPutHAB num2str(HAB) '.jpg']);
        HAB = HAB +1;
        imwrite(uint8(flipud(thisImage)),[outPutHAB num2str(HAB) '.jpg']);
        HAB = HAB +1;
        imwrite(uint8(fliplr(thisImage)),[outPutHAB num2str(HAB) '.jpg']);
        HAB = HAB +1;
        imwrite(uint8(fliplr(flipud(thisImage))),[outPutHAB num2str(HAB) '.jpg']);
        HAB = HAB +1;
    end
    
end
allMax;

function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1 
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
