function getDataOuter;
clear; close all;

if ismac
    filenameBase = '/Users/csprh/Dlaptop/MATLAB/MYCODE/HAB/WORK/HAB/florida1/';
else
    filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida1/';
end

outH5name = [filenameBase 'LSTMData/LSTMFlor1.h5']
distanceOffset = [1 1 1];

h5files=dir([filenameBase '*.h5.gz']);
numberOfH5s=size(h5files,1); 
limitLength = 10000;

thisInd = 1;
for ii = 1: numberOfH5s %Loop through all the ground truth entries
    try
    system(['rm ' filenameBase '*.h5']);
    gzh5name = [filenameBase h5files(ii).name];
    gunzip(gzh5name);
	h5name = gzh5name(1:end-3);

    thisCount= h5read(h5name,'/thisCount');
    [ 'thisCount = ' num2str(thisCount) ];  
    thisH5Info = h5info(h5name);
    thisH5Groups = thisH5Info.Groups;
    numberOfGroups = size(thisH5Groups,1);
    finalTimeOrderedOutput  = [];
    for groupIndex = 2: numberOfGroups
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        thesePoints = h5read(h5name, [thisGroupName{groupIndex} '/Points']);
        theseDistances = [thesePoints(:,1)-25 thesePoints(:,2)-25 thesePoints(:,4)];
        theseDistances(:,1) = theseDistances(:,1)* distanceOffset(1);
        theseDistances(:,2) = theseDistances(:,2)* distanceOffset(2);
        theseDistances(:,3) = theseDistances(:,3)* distanceOffset(3);
        theseDistances = sqrt(sum(theseDistances.^2,2));
        theseValues = thesePoints(:,3);
        distanceOuput = [theseDistances theseValues groupIndex * ones(size(thesePoints,1),1) ];
        
        finalTimeOrderedOutput = [finalTimeOrderedOutput ;distanceOuput];
        
    end
    [dummy idx] = sort((finalTimeOrderedOutput(:,1)));
    sortedTimeOrdOut = finalTimeOrderedOutput(idx,:);
    thisLength = size(sortedTimeOrdOut,1);
    if thisLength > limitLength; 
        sortedTimeOrdOut = sortedTimeOrdOut(1:limitLength,:);
    else
        sortedTimeOrdOut  = [sortedTimeOrdOut; zeros(limitLength-thisLength,size(sortedTimeOrdOut,2))];
    end
    outData(:,:,ii) = sortedTimeOrdOut';
    lengthTime(thisInd) =size(sortedTimeOrdOut,1);
    
    isHAB(thisInd) = thisCount > 0;
    thisInd = thisInd + 1;
    %['thisInd = ' num2str(thisInd) ' max = ' num2str(max(thisMax))]
    %[ 'min = '    num2str(min(thisMin))]
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end


if exist(outH5name, 'file')==2;  delete(outH5name);  end
hdf5write(outH5name,'/XLSTMData',outData);
hdf5write(outH5name,'/YLSTMData',double(isHAB), 'WriteMode','append');

function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1 
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
