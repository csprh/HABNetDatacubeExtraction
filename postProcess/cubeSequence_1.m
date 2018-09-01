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
totalDiscount = 0;
for ii = 1: numberOfH5s %Loop through all the ground truth entries

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

    
    % Find Unreliable datapoins
    % - loop through all groups
    % - Find if central position contains nothing (in all bands)
    % For each band
    % - Create an image for each day (averaged over all inputs)
    % - Create a zero image for day that does not exist
    % - Find number of days from XML file
    % - Create directory structure: (test, train)(HAB,
    % noHAB)(Modality)(PNGs for each time)
    % For each band
    % - Create train / test structure
    % - Create class structure
    % - Output JPGs into the structure
    % - Modify data.py to get the data into the same structure
    
    % Loop through all groups (apart from GEBCO) and discount
    groupIndex = 3;  %Just choose one.  This should reflect 
    thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
    theseIms = h5read(h5name, [thisGroupName{groupIndex} '/Ims']);
    
    numberOfIms = size(theseIms,3);
    for iii = 1:numberOfIms
        firstIm = theseIms(:,:,iii);
        centrePatchP = size(firstIm)/2+2;
        centrePatchM = size(firstIm)/2-1;
        centrePatch = firstIm(centrePatchM(1):centrePatchP(:),centrePatchM(2):centrePatchP(2));
        
        totNumberCP(iii) = prod(size(centrePatch));
        zNumberCP(iii) = sum(centrePatch(:)==0);
        quotCP(iii) = zNumberCP(iii) / totNumberCP(iii);
        
        totNumber(iii) = prod(size(theseIms));
        zNumber(iii) = sum(theseIms(:)==0);
        quot(iii) = zNumber(iii) / totNumber(iii);
    end
    allThereCP = (quotCP>0.2);
    allThere = (quot>0.5);
    allThereTotal = [ allThereCP allThere ];
    thisDiscount = (sum(allThereTotal) ~= length(allThereTotal));
    
    if thisDiscount == 1
        totalDiscount= totalDiscount+1;
    end
    totalDiscount
    clear totNumberCP zNumberCP quotCP totNumber zNumber quot 
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end




function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1 
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
