function [rmcommand, pythonStr, tmpStruct] = getHABConfig
%% This Code generates the remove and python commands together with 
%% configuration information (xml file name)
%
% USAGE:
%   [rmcommand, pythonStr, tmpStruct] = getHABConfig
% INPUT:
%   -
% OUTPUT:
%   rmcommand: remove command name for the operating system
%   pythonStr: python string command name for the operating system
%   tmpStruct: configuration information extracted from config file

% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill April 2019

GULF = 1;

if ismac
    rmcommand = 'rm ';
    pythonStr = '/usr/local/bin/python3';
    tmpStruct = xml2struct('configHABmac.xml');
elseif isunix
    pythonStr = 'python';
    rmcommand = 'rm ';
    [~, thisCmd] = system('rpm --query centos-release');
    isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-7.1908.0.el7.centos.x86_64');
    if isUnderDesk == 1
        if GULF == 0
            tmpStruct = xml2struct('configHABunderDesk.xml');
        else
            tmpStruct = xml2struct('configHABunderDeskGULF.xml');
        end
    else
        tmpStruct = xml2struct('configHAB.xml');
    end
elseif ispc
    % Code to run on Windows platform
    pythonStr = 'py';
    tmpStruct = xml2struct('configHAB_win.xml');
    rmcommand = ['del ' pwd '\' ];
else
    disp('Platform not supported')
end
