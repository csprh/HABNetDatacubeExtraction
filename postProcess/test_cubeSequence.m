function test_cubeSequence
%% This Code loops through all the h5 test files and generates
%% a directory of images in a folder for ingress into Machine Learning model
%% for testing
% 
% ...Also creates a record of the tested data points in file latLonList.txt
% Inside latLonList.txt a line is entered for each of the datapoints
% Each line is [Index latitude longitude] where index is the name of the 
% output directory
%
% USAGE:
%   test_cubeSequence;
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill April 2019
clear; close all;
addpath('..');
[rmcommand, ~, tmpStruct] = getHABConfig;

sample_date = str2num(tmpStruct.confgData.testDate.Text);
cubesDir = tmpStruct.confgData.testDir.Text;
imsDir = tmpStruct.confgData.testImsDir.Text;
resolution = str2num(tmpStruct.confgData.resolution.Text);
distance1 = str2num(tmpStruct.confgData.distance1.Text);
outputRes = str2num(tmpStruct.confgData.outputRes.Text);
alphaSize = str2num(tmpStruct.confgData.alphaSize.Text);
numberOfDaysInPast  = str2num(tmpStruct.confgData.numberOfDaysInPast.Text);

%The input range is usually 50 by 50 samples (in projected space)
%The output resolution is 1000m (1km).  This results in 100x100 pixels images
%AlphaSize controls the interpolation projected points to output image

inputRangeX = [0 distance1/resolution];
inputRangeY = [0 distance1/resolution];

imsDir = [imsDir filesep num2str(sample_date) filesep];
latLonList = 'latLonList.txt';

% REMOVE Previous output directory
% NOTE: May need to be changed for PC
system([rmcommand '-rf ' imsDir]);
mkdir(imsDir);

h5files=dir([cubesDir '*.h5.gz']);
numberOfH5s=size(h5files,1);

load groupMaxAndMin %load the max and minima of the mods created by training

fileID = fopen([imsDir latLonList],'w+');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop through all the ground truth entries%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1: numberOfH5s
    try
        %% Process input h5 file
        system([rmcommand cubesDir '*.h5']);
        gzh5name = [cubesDir h5files(ii).name];
        gunzip(gzh5name);
        h5name = gzh5name(1:end-3);

        lon = h5readatt(h5name,'/GroundTruth/','thisLon');
        lat = h5readatt(h5name,'/GroundTruth/','thisLat');
        
        fprintf(fileID,'%d %d %d\n',ii, lat, lon);

        %Split output into train/test, HAB Class directory, Ground truth line
        %number, Group Index
        baseDirectory = [imsDir num2str(ii)] ;
        
        outputImagesFromDataCube(baseDirectory,  numberOfDaysInPast, groupMinMax, inputRangeX, inputRangeY, alphaSize, outputRes, h5name);
        
    catch
        [ 'caught at = ' num2str(ii) ]
    end
end
fclose(fileID);


