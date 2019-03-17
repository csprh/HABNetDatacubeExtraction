function outputImagesFromDataCube(baseDirectory,  numberOfDays, groupMinMax, inputRangeX, inputRangeY, alphaSize, outputRes, h5name)

%% This Code loops through all modalities within the given h5 file (h5name) and generates
%% A directory of images in a folder for ingress into Machine Learning

% USAGE:
%   outputImagesFromDataCube(baseDirectory,  numberOfDays, groupMinMax, inputRangeX, inputRangeY, alphaSize, outputRes, h5name)
% INPUT:
%   baseDirectory: Directory to put the output images (0,1,2....directories
%   created to put modalities into...each image 0.png, 1.png etc are the
%   days output)
%   numberOfDays: Number of days
%   inputRangeX: Range of output for images ([0:50])
%   inputRangeY: Range of output for images ([0:50])
%   outputRes: Resolution (in metres) of quantise bins output
%   groupMinMax: Array of Minima and Maxima of the modalities
%   h5name: Name of the input H5 file
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019

thisH5Info = h5info(h5name);
thisH5Groups = thisH5Info.Groups;
numberOfGroups = size(thisH5Groups,1);

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
for groupIndex = 2: numberOfGroups
    thisGroupIndex = groupIndex-1;
    thisBaseDirectory = [baseDirectory '/' num2str(thisGroupIndex) '/'];
    mkdir(thisBaseDirectory);
    
    %Get projected points (on 50x50 grid), if not exist then
    %generate blank output
    try
        PointsProj = h5read(h5name, [thisH5Groups(groupIndex).Name '/PointsProj']);
    catch
        
    end
    
    %%Loop through days, quantise them, sum, clip and output
    for thisDay  = 1:numberOfDays
        try
            if thisGroupIndex == 1 %GEBCO
                input.xp = PointsProj(:,1);
                input.yp = PointsProj(:,2);
                input.up = PointsProj(:,3);
                outputImage = griddata(input.xp, input.yp,  input.up, output.xq, output.yq);
                landInd = outputImage>0;
                outputImage(landInd) = 0;
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
            end
            
            outputImage = outputImage-groupMinMax(thisGroupIndex,1);
            outputImage = 255*(outputImage./(groupMinMax(thisGroupIndex,2)-groupMinMax(thisGroupIndex,1)));
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

