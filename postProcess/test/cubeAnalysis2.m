function cubeAnalysis1
clear; close all;

if ismac
    filenameBase = '/Users/csprh/tmp/florida2/';
else
    filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida2/';
end


h5files=dir([filenameBase '*.h5.gz']);
numberOfH5s=size(h5files,1);

thisGebcoData = [];
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
        
        groupIndex = 2
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        theseIms = h5read(h5name, [thisGroupName{groupIndex} '/Ims']);
        firstIm = theseIms(:,:,1);
        thisGebcoData = [thisGebcoData; firstIm(:)];  
        
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end

save thisGebcoData thisGebcoData;



function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
