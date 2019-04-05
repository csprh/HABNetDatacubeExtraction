function test_genAllH5s
%% Top level code that generates test Lat and Lon points according to test_getLatLonArray
%% then loops through all datapoints and calls genSingleH5s.m to form all H5 datacubes
%
% USAGE:
%   test_genAllH5s;
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill 26th June 2018
% Updated March 2019 PRH
% Updates for WIN compatibility: JVillegas 21 Feb 2019, Khalifa University
clear; close all;

% Settings
% Gulf....can be 0 (Florida) or 1 (Gulf)
% deltaran....resolution of lat and lon range
% removeFreq....the number of samples processed before all .nc are deleted

gulf = 1;    deltaran = 0.5;  removeFreq= 500;  
[rmcommand, pythonStr, tmpStruct] = getHABConfig;

%% load all config from XML file
sample_date = str2num(tmpStruct.confgData.testDate.Text);
confgData.inputFilename = tmpStruct.confgData.inputFilename.Text;
confgData.gebcoFilename = tmpStruct.confgData.gebcoFilename.Text;
confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
confgData.outDir = tmpStruct.confgData.testDir.Text;
confgData.downloadDir = tmpStruct.confgData.downloadFolder.Text;
confgData.distance1 = str2double(tmpStruct.confgData.distance1.Text);
confgData.resolution = str2double(tmpStruct.confgData.resolution.Text);
confgData.numberOfDaysInPast = str2double(tmpStruct.confgData.numberOfDaysInPast.Text);
confgData.numberOfSamples = str2double(tmpStruct.confgData.numberOfSamples.Text);
confgData.mods = tmpStruct.confgData.Modality;
confgData.pythonStr = pythonStr;

[latitude, longitude] =  test_getLatLonArray(gulf, deltaran);

if ~exist(confgData.outDir, 'dir')
    mkdir(confgData.outDir)
end

system([rmcommand confgData.outDir '*.h5']);
system([rmcommand confgData.outDir '*.h5.gz']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Loop through all samples in .mat Ground Truth File %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
startIndex = 1;
outputIndex = startIndex;
numberOfSamples = length(latitude);
for ii = startIndex: numberOfSamples %Loop through all the ground truth entries
    try
        if rem(ii,removeFreq) == 1 && ii>startIndex       % Delete the .nc files (every tenth one)
            system([rmcommand confgData.downloadDir '*.nc']);
        end
        
        inStruc.ii = ii;
        inStruc.thisLat = latitude(ii);
        inStruc.thisLon = longitude(ii);
        inStruc.dayEnd = sample_date;
        inStruc.thisCount = 0; %these are test points therefore no counts
        
        fileName = ['Cube_' sprintf('%05d',outputIndex) '_' sprintf('%05d',ii) '_' num2str(sample_date) '.h5'];
           
        inStruc.h5name = [confgData.outDir fileName];
        
        genSingleH5s(inStruc, confgData);
        
        % Zip up the data and delete the original
        gzip(inStruc.h5name);
        system([rmcommand confgData.outDir '*.h5']);
        outputIndex = outputIndex+1;
    catch e
        str_iden = num2str(ii);
        logErr(e,str_iden)
        continue
    end
end
end


function logErr(e,str_iden)
%fileID = fopen('errors.txt','at');
%identifier = ['Error procesing sample ',str_iden, ' at ', datestr(now)];
%text = [e.identifier, '::', e.message];
%fprintf(fileID,'%s\n\r ',identifier);
%fprintf(fileID,'%s\n\r ',text);
%fclose(fileID);
end
