function outputImagesFromDataCube(baseDirectory,  numberOfDays, groupMinMax, inputRangeX, inputRangeY, alphaSize, outputRes, h5name)
%% This code generates quantised images for an input H5 datacube
%% It loops through all modalities within the given H5 file (h5name) and generates
%% A directory of images in a folder for ingress into Machine Learning

% USAGE:
%   outputImagesFromDataCube(baseDirectory,  numberOfDays, groupMinMax, inputRangeX, inputRangeY, alphaSize, outputRes, h5name)
% INPUT:
%   baseDirectory: Directory to put the output images (0,1,2....directories
%   created to put modalities into...each image 1.png, 2.png etc are the
%   days output)
%   numberOfDays: Number of days in temporal range of datacube
%   groupMinMax: Array of Minima and Maxima of the modalities
%   inputRangeX: Range of output for images ([0:50])
%   inputRangeY: Range of output for images ([0:50])
%   alphaSize: Control of resampling
%   outputRes: Resolution (in metres) of quantise bins output
%   h5name: Name of the input H5 file
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill July 2019

thisH5Info = h5info(h5name);
modNames = h5read(h5name, '/Modnames');
modNo = size(modNames,1);
% Generate Output Interpolation Variables
inputRes = thisH5Info.Groups(1).Attributes(10);
inputRes = inputRes.Value;
fract = outputRes / inputRes ;
xq = inputRangeX(1) + fract/2 : fract : inputRangeX(2) - fract/2;
yq = inputRangeY(1) + fract/2 : fract : inputRangeY(2) - fract/2;
[output.xq, output.yq] = meshgrid(xq, yq);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop through all modalities              %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for thisGroupIndex = 1: modNo + 1
    thisBaseDirectory = [baseDirectory '/' num2str(thisGroupIndex) '/'];
    mkdir(thisBaseDirectory);
    
    try
        thisInd = thisGroupIndex;
        if (thisGroupIndex == modNo + 1)
            thisInd = 3;
        end
        thisModName = strtrim(modNames{thisInd}); %Remove whitespaces
        thisModName(thisModName==0) = ' ';
        thisModName = strtrim(thisModName);
        PointsProj = h5read(h5name, ['/' thisModName '/PointsProj']);
    catch
        
    end
    
    %%Loop through days, quantise them, sum, clip and output
    for thisDay  = 1:numberOfDays
        try
            if thisGroupIndex == 1 %GEBCO
                input.xp = PointsProj(:,1);
                input.yp = PointsProj(:,2);
                input.up = PointsProj(:,3);
                outputImage = griddata(input.yp, input.xp,  input.up, output.xq, output.yq);
                F = scatteredInterpolant(input.xp, input.yp,  input.up);
                outputImage = F(output.xq, output.yq);
                landInd = outputImage>0;
                outputImage(landInd) = 0;
                thisMin = groupMinMax(1,1);    thisMax = groupMinMax(1,2);
            elseif thisGroupIndex == 2 %Bimonth
                input.xp = PointsProj(:,1);
                input.yp = PointsProj(:,2);
                input.up = PointsProj(:,3);
                outputImage = griddata(input.yp, input.xp,  input.up, output.xq, output.yq, 'nearest');

                outputImage(landInd) = 0;
                biMonthImage = outputImage;
                thisMin = groupMinMax(3,1);    thisMax = groupMinMax(3,2); %Standardise the minmax from Chlor_a              
            else
                zp = PointsProj(:,4);
                quantEdge1 = thisDay-1; quantEdge2 = thisDay;
                theseIndices = (zp>=quantEdge1) & (zp<quantEdge2);
                
                if length(theseIndices)==0
                    outputImage = zeros(size(landInd));
                else
                    input.xp = PointsProj(theseIndices,1);
                    input.yp = PointsProj(theseIndices,2);
                    input.up = PointsProj(theseIndices,3);
                    input.isLand = landInd;
                    
                    outputImage = getImage(output, input, alphaSize);
                end
                thisMin = groupMinMax(thisInd,1);   thisMax = groupMinMax(thisInd,2);
            end
            
            if thisGroupIndex == (modNo + 1) % Make Differnce
                outputImage = biMonthImage - outputImage;
                thisMin = groupMinMax(3,1)-groupMinMax(3,2);   thisMax = groupMinMax(3,2)-groupMinMax(3,1); 
            end
            
            outputImage = outputImage-thisMin;
            outputImage = round(255.*(outputImage./(thisMax-thisMin)));
            outputImage(outputImage < 0) = 0; outputImage(outputImage > 255) = 255;
            
            imwrite(uint8(outputImage),[thisBaseDirectory  sprintf('%02d',thisDay),'.png']);
        catch
            outputImage = ones(size(output.xq))*NaN;
            imwrite(uint8(outputImage),[thisBaseDirectory  sprintf('%02d',thisDay),'.png']);
        end
    end
end

function outputImage = getImage(thisOutput, thisInput, alphaSize)
%% This Code grids the data in thisInput to the grid of thisOutput using 
%% Gridding and alphashape

% USAGE:
%   outputImage = getImage(output, input, alphaSize)
% INPUT:
%   thisOuput: definition of output shape
%   thisInput: definition of input shape
%   alphaSize: definition of parameters for alphaShape
% OUTPUT:
%   outputImage: Raster output image

% If there is very small amounts of input data just resturn a NaN image
if length(thisInput.xp) < 10
    outputImage = ones(size(thisOutput.xq))*NaN;
    return;
end
try
    outputImage = griddata(thisInput.xp, thisInput.yp,  thisInput.up, thisOutput.xq, thisOutput.yq);
    shp = alphaShape(thisInput.xp, thisInput.yp,  alphaSize);
    thisin = inShape(shp, thisOutput.xq, thisOutput.yq);
    
    outputImage(thisin==0) = NaN;
    outputImage(thisInput.isLand==1) = NaN;
catch
    outputImage = ones(size(thisOutput.xq))*NaN;
end

