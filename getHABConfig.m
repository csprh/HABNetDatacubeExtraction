function [rmcommand, tmpStruct] = getHABConfig
%% This Code generates the remove command and configuration information
%
% USAGE:
%   [rmcommand, tmpStruct] = getHABConfig
% INPUT:
%   -
% OUTPUT:
%   rmcommand: remove command name for the operating system
%   tmpStruct: configuration information extracted from config file

% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019



if ismac
    rmcommand = 'rm ';
    tmpStruct = xml2struct('configHABmac.xml');
elseif isunix
    rmcommand = 'rm ';
    [~, thisCmd] = system('rpm --query centos-release');
    isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-6.1810.2.el7.centos.x86_64');
    if isUnderDesk == 1
        tmpStruct = xml2struct('configHABunderDesk.xml');
    else
        tmpStruct = xml2struct('configHAB.xml');
    end
elseif ispc
    % Code to run on Windows platform
    tmpStruct = xml2struct('configHAB_win.xml');
    rmcommand = ['del ' pwd '\' ];
else
    disp('Platform not supported')
end
