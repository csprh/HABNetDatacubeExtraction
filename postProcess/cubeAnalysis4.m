function cubeAnalysis1
clear; close all;

if ismac
    filenameBase = '/Users/csprh/tmp/florida4/';
else
    [dummy, thisCmd] = system('rpm --query centos-release');
    isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-6.1810.2.el7.centos.x86_64');
    if isUnderDesk == 0
        filenameBase = '/mnt/storage/home/csprh/scratch/HAB/florida4/';
    else
        filenameBase = '/home/cosc/csprh/linux/HABCODE/scratch/HAB/florida4/';
    end
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
        inputRes = thisH5Info.Groups(1).Attributes(10);
        inputRes = inputRes.Value;
        thisH5Groups = thisH5Info.Groups;
        numberOfGroups = size(thisH5Groups,1);
        
        
        inputRangeX = [0 50];
        inputRangeY = [0 50];
        outputRes = 1000;
        fract = outputRes / inputRes ;
        xq = inputRangeX(1) + fract/2 : fract : inputRangeX(2) - fract/2;
        yq = inputRangeY(1) + fract/2 : fract : inputRangeY(2) - fract/2;
        [output.xq, output.yq] = meshgrid(xq, yq);
        
        
        groupIndex = 2;
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        PointsProj = h5read(h5name, [thisGroupName{groupIndex} '/PointsProj']);

        landInd = PointsProj(:,3)>0;
        input.xp = PointsProj(landInd,1);
        input.yp = PointsProj(landInd,2);
              
        isLand = hist3([input.yp, input.xp], {yq xq});
        
        isLand = isLand ==0;
        
        groupIndex = 8;
        thisGroupName{groupIndex} = thisH5Groups(groupIndex).Name;
        PointsProj = h5read(h5name, [thisGroupName{groupIndex} '/PointsProj']);
          
        zp = PointsProj(:,4);
        for thisDay  = 1:numberOfDays
            quantEdge1 = thisDay-1; quantEdge2 = thisDay;
            theseIndices = (zp>=quantEdge1) & (zp<quantEdge2);
            
            alphaSize = 2;
            
            input.xp = PointsProj(theseIndices,1);
            input.yp = PointsProj(theseIndices,2);
            input.up = PointsProj(theseIndices,3);
            input.isLand = isLand;
            
            outputImage = getImage(output, input, alphaSize);
            
        end
        thisGebcoData = [thisGebcoData; firstIm(:)];
        
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end

save thisGebcoData thisGebcoData;

function outputImage = getImage(output, input, alphaSize)

if length(input.xp) == 0
    outputImage = ones(size(input.xq))*NaN;
    return;
end
outputImage = griddata(input.xp, input.yp,  input.up, output.xq, output.yq);
shp = alphaShape(input.xp, input.yp,  alphaSize);
thisin = inShape(shp, output.xq, output.yq);

outputImage(thisin==0) = NaN;
outputImage(input.isLand==1) == NaN;


function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
