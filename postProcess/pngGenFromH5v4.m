function getDataOuter;
clear; close all;

if ismac
    filenameBase1 = '~/Dlaptop/MATLAB/MYCODE/HAB/WORK/HAB/florida1/';
    filenameBase2 = '~/Dlaptop/MATLAB/MYCODE/HAB/WORK/HAB/florida1/';
else
    filenameBase1 = '/mnt/storage/home/csprh/scratch/HAB/florida1/';
    filenameBase2 = '/mnt/storage/home/csprh/scratch/HAB/CNNIms/florida1/';
end
outPutHABTrain = [filenameBase2 'train_dir/1/'];
outPutNoHABTrain = [filenameBase2 'train_dir/0/'];
outPutHABVal = [filenameBase2 'val_dir/1/'];
outPutNoHABVal = [filenameBase2 'val_dir/0/'];

valProp = 0.2;
h5files=dir([filenameBase1 '*.h5.gz']);
numberOfH5s=size(h5files,1);
valIndex = round(numberOfH5s-numberOfH5s*valProp);
HAB = 0;
NoHAB = 0;
thisInd = 1;
for ii = 1: numberOfH5s %Loop through all the ground truth entries    
    try
    gzh5name = [filenameBase h5files(ii).name];
    gunzip(gzh5name);
	h5name = gzh5name(1:end-3);

    thisCount= h5read(h5name,'/thisCount');
    [ 'thisCount = ' num2str(thisCount) ]  
    thisH5Info = h5info(h5name);
    thisH5Groups = thisH5Info.Groups;
    numberOfGroups = size(thisH5Groups,1);
    for groupIndex = 1: numberOfGroups
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        Ims{groupIndex}= h5read(h5name, [thisGroupName{groupIndex} '/Ims']);
    end
    isHAB(thisInd) = thisCount > 0;
    theseImages = cat(3,Ims{7},Ims{14});
    theseImages(theseImages==0)=NaN;
     
    thisImage = nanmean(Ims{7}, 3);
    fullNumber = prod(size(thisImage));
    nanNumber = sum(isnan(thisImage(:)));
    
    thisRatio = nanNumber / fullNumber;
    %if thisRatio > 0.8
    %    continue;
    %end
    thisMax(thisInd) = max(thisImage(:));
    thisMin(thisInd) = min(thisImage(:));
    thisImage(isnan(thisImage))=0;
    thisImage = imresize(thisImage,[128 128]);
    %thisImage = round(thisImage*(255/466.5));
    thisImage = round(thisImage*(255/78.5));
    thisImage(thisImage>255) = 255;
    %hist(thisImage(:),100); pause(0.5);
    if (sum(thisImage(:)==0)) > 8100
        continue;
    end
    if ii > valIndex
        if isHAB(thisInd)==0
            imwrite(uint8(thisImage),[outPutNoHABTrain num2str(NoHAB) '.jpg']);
            NoHAB = NoHAB +1;
        else
            imwrite(uint8(thisImage),[outPutHABTrain num2str(HAB) '.jpg']);
            HAB = HAB +1;
        end
    else
        if isHAB(thisInd)==0
            imwrite(uint8(thisImage),[outPutNoHABVal num2str(NoHAB) '.jpg']);
            NoHAB = NoHAB +1;
        else
            imwrite(uint8(thisImage),[outPutHABVal num2str(HAB) '.jpg']);
            HAB = HAB +1;
        end
    end
    thisInd = thisInd + 1;
    %['thisInd = ' num2str(thisInd) ' max = ' num2str(max(thisMax))]
    %[ 'min = '    num2str(min(thisMin))]
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end


function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1 
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
