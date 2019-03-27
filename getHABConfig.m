function [confgData] = getHABConfig(xmlConfig)
%% This Code generates the remove command and configuration information
%
% USAGE:
%   [rmcommand, confgData] = getHABConfig
% INPUT:
%   -
% OUTPUT:
%   rmcommand: remove command name for the operating system
%   pythonStr: python string command name for the operating system
%   tmpStruct: configuration information extracted from config file

% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019

    if ismac
        rmcommand = 'rm ';
        pythonStr = '/usr/local/bin/python3';
        tmpStruct = xml2struct(xmlConfig);
    elseif isunix
        pythonStr = 'python';
        rmcommand = 'rm ';
        tmpStruct = xml2struct(xmlConfig);
    elseif ispc
        % Code to run on Windows platform
        pythonStr = 'py';
        rmcommand = ['del ' pwd '\' ];        
        tmpStruct = xml2struct(xmlConfig);
    end

    %% load all config from XML file
    confgData.inputFilename = tmpStruct.confgData.inputFilename.Text;
    confgData.gebcoFilename = tmpStruct.confgData.gebcoFilename.Text;
    confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
    confgData.outDir = tmpStruct.confgData.outDir.Text;
    confgData.downloadDir = tmpStruct.confgData.downloadFolder.Text; 
    confgData.distance1 = str2double(tmpStruct.confgData.distance1.Text);
    confgData.resolution = str2double(tmpStruct.confgData.resolution.Text);
    confgData.numberOfDaysInPast = str2double(tmpStruct.confgData.numberOfDaysInPast.Text);
    confgData.numberOfSamples = str2double(tmpStruct.confgData.numberOfSamples.Text);
    confgData.mods = tmpStruct.confgData.Modality;
    confgData.command.pythonStr = pythonStr;
    confgData.command.rm = rmcommand;
