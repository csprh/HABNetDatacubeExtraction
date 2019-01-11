function cubeAnalysis1
clear; close all;

if ismac
    filenameBase = '/Users/csprh/tmp/florida4/';
else
    filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida4/';
end


h5files=dir([filenameBase '*.h5.gz']);
numberOfH5s=size(h5files,1);

thisGebcoData = [];
numberOfDays = 10;
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
        
        groupIndex = 8
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        PointsProj = h5read(h5name, [thisGroupName{groupIndex} '/PointsProj']);
        DisplayPoints = permute(PointsProj,[1 2 4 3]);
        
        
        alphaSize = 2;
        ind = PointsProj(:,4)>9;
        xp = PointsProj(ind,1);  
        yp = PointsProj(ind,2);
        up = PointsProj(ind,3);
        
        xq = 1:0.5:50;
        yq = 1:0.5:50;
        [xq2,yq2] = meshgrid(xq, yq);
        
        ugrid = griddata(xp, yp, up, xq2, yq2);
        shp = alphaShape(xp, yp, alphaSize);
        thisin = inShape(shp, xq2, yq2);
        
        imagesc(thisin);
        ugrid(thisin==0) = NaN;

        imagesc(ugrid)
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
