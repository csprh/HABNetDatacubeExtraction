function getDataOuter;
clear; close all;

filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida1/';
outPutHAB = [filenameBase 'cnnData/1/'];
outPutNoHAB = [filenameBase 'cnnData/0/'];
numberOfH5s = 16289;

allMin = 100000; allMax = 0; 
HAB = 0;
NoHAB = 0;
thisInd = 1;
for ii = 1: numberOfH5s %Loop through all the ground truth entries
	h5name = [filenameBase 'flor' num2str(ii) '.h5'];
	
	%h5disp(h5name);
	try

    thisCount= h5read(h5name,'/thisCount');

    isHAB(thisInd) = thisCount >0;
    theseImages = h5read(h5name,'/chlor_a/Ims');
    theseImages(theseImages==0)=NaN;
    
    thisImage = nanmean(theseImages,3);
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
