function cubeAnalysis_1
clear; close all;

if ismac
    filenameBase = '/Users/csprh/tmp/florida2/';
else
    filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida2/';
end


h5files=dir([filenameBase '*.h5.gz']);
numberOfH5s=size(h5files,1); 
%numberOfH5s = 200;

totalDeltaDates  = [];
thisInd = 1;
for ii = 1: numberOfH5s %Loop through all the ground truth entries
    ii
    try
    system(['rm ' filenameBase '*.h5']);
    gzh5name = [filenameBase h5files(ii).name];
    gunzip(gzh5name);
	h5name = gzh5name(1:end-3);

    thisCount = h5readatt(h5name,'/GroundTruth/','thisCount');
    [ 'thisCount = ' num2str(thisCount) ];  
    thisH5Info = h5info(h5name);
    thisH5Groups = thisH5Info.Groups;
    numberOfGroups = size(thisH5Groups,1);

    for groupIndex = 3: numberOfGroups
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        theseIms = h5read(h5name, [thisGroupName{groupIndex} '/Ims']);
        firstIm = theseIms(:,:,1);
        centrePatchP = size(firstIm)/2+2;
        centrePatchM = size(firstIm)/2-1;
        centrePatch = firstIm(centrePatchM(1):centrePatchP(:),centrePatchM(2):centrePatchP(2));
        
        totNumberCP(ii,groupIndex-2) = prod(size(centrePatch));
        zNumberCP(ii,groupIndex-2) = sum(centrePatch(:)==0);
        quotCP(ii,groupIndex-2) = zNumberCP(ii,groupIndex-2) / totNumberCP(ii,groupIndex-2);
        
        totNumber(ii,groupIndex-2) = prod(size(theseIms));
        zNumber(ii,groupIndex-2) = sum(theseIms(:)==0);
        quot(ii,groupIndex-2) = zNumber(ii,groupIndex-2) / totNumber(ii,groupIndex-2);
        
        
        theseDeltaDates = h5read(h5name, [thisGroupName{groupIndex} '/theseDeltaDates']);
        totalDeltaDates = [ totalDeltaDates theseDeltaDates];
        DDsize(ii,groupIndex-2) = length(theseDeltaDates);
        
    end
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end

save analysis  totNumberCP zNumberCP quotCP totNumber zNumber quot totalDeltaDates DDsize;
hist(quotCP(:),100);


function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1 
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
