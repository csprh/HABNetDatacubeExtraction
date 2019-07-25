function outputAllBiIMs
%% Top level code that loads xml config, loads .mat ground truth file,
%  then loops through all datapoints and calls genSingleH5s.m to form all H5 datacubes
%
% USAGE:
%   train_genAllH5s;
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill 26th June 2018
% Updated March 2019 PRH
% Updates for WIN compatibility: JVillegas 21 Feb 2019, Khalifa University
clear; close all;
addpath('./..');
[~, ~, tmpStruct] = getHABConfig;


%% load all config from XML file
confgData.outDir = tmpStruct.confgData.trainDir.Text;
biDir =  [confgData.outDir 'BimonthlyAverageDirectory'];

biDirOut = [biDir '/Ims/'];




h5files=dir([biDir '/*.h5']);
numberOfH5s=size(h5files,1);

thisMin = 0;
thisMax = 400;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop through all the ground truth entries%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1: numberOfH5s
    
    h5name = [biDir h5files(ii).name];
    outputImage = h5read(h5name,'/Chlor_a');
    outputImage = outputImage-thisMin;
    outputImage = round(255.*(outputImage./(thisMax-thisMin)));
    outputImage(outputImage < 0) = 0; outputImage(outputImage > 255) = 255;
    
    thisName = h5files(ii).name;
    thisName = thisName(1:end-3);
    imwrite(uint8(outputImage),[biDirOut thisName '.png']);
end
