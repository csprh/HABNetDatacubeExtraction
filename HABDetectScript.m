function HABDetectScript(h5name, outputDirectory)
%% This Code takes a datacube and outputs quantised images for all days and
%% modalities in the outputDirectory.
%% This script generates a number of png files from the datacube over the
%% number of days in the datacube.  The bottleneck features are extracted
%% from each png file using extract_features.py
%% Once the numpy file is extracted from each modality, testHAB.py is used
%% to generate a classification.  testHAB.py injests numpy file generated 
%% by extract_features.py, loads a model and generates a classfication 
%% probability
%
% USAGE:
%   HABDetectScript('/home/cosc/csprh/linux/HABCODE/scratch/HAB/tmpTest/testCubes/Cube_09073_09081_737173.h5', '/home/cosc/csprh/linux/HABCODE/scratch/HAB/tmpTest/CNNIms');
% INPUT:
%   h5name: Name of the input
%   outputDirectory
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019

addpath('postProcess');
[~, tmpStruct] = getHABConfig;
if ismac
    pythonStr = '/usr/local/bin/python3';
elseif isunix
    pythonStr = 'python3';
elseif ispc
    pythonStr = 'py';
end

resolution = str2num(tmpStruct.confgData.resolution.Text);
distance1 = str2num(tmpStruct.confgData.distance1.Text);
numberOfDays = str2num(tmpStruct.confgData.numberOfDaysInPast.Text);
outputRes = str2num(tmpStruct.confgData.outputRes.Text);
alphaSize = str2num(tmpStruct.confgData.alphaSize.Text);

inputRangeX = [0 distance1/resolution];
inputRangeY = [0 distance1/resolution];

load groupMaxAndMin

outputImagesFromDataCube(outputDirectory, numberOfDays, groupMinMax, inputRangeX, inputRangeY, alphaSize, outputRes, h5name);
origDir = pwd;
cd ..; cd modelHAB;
thisDir = pwd;
exeName = [pythonStr ' extract_features.py ' thisDir '/cnfgXMLs/NASNet11_lstm0.xml ' outputDirectory];
system(exeName);
exeName = [pythonStr ' testHAB.py ' thisDir '/cnfgXMLs/NASNet11_lstm0.xml ' outputDirectory];
prob = system(exeName);
cd (origDir);



