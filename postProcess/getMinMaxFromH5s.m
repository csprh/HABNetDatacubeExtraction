function [thisMax, thisMin] = getMinMaxFromH5s(filenameBase)
%% This Code loops through al the H5 output files and generates
%% The maximum and minimum values for each modality.
%% These are then output into the maximum vector thisMax and
%% the minimum vector thisMin
% USAGE:
%   [thisMax, thisMin] = getMinMaxFromH5s(filenameBase)
% INPUT:
%   filenameBase: Directory that holds all compressed h5 datacubes
% OUTPUT:
%   thisMax: Vector of maximum values for each modality
%   thisMin: Vector of minimum values for each modality

% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019
close all;

h5files=dir([filenameBase '*.h5.gz']);
numberOfH5s=size(h5files,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop through all the ground truth entries%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1: numberOfH5s
    ii
    try
        %% Process input h5 file
        system(['rm ' filenameBase '*.h5']);
        gzh5name = [filenameBase h5files(ii).name];
        gunzip(gzh5name);
        h5name = gzh5name(1:end-3);
        modNames = h5read(h5name, '/Modnames');
        modNo = size(modNames,1);

        if ii == 1
            % Initalise
            thisMax = ones(modNo, numberOfH5s)*NaN;
            thisMin = ones(modNo, numberOfH5s)*NaN;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%Loop through all modalities              %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for thisGroupIndex = 1: modNo
            thisModName = strtrim(modNames{thisGroupIndex}); %Remove whitespaces
            thisModName(thisModName==0) = ' ';
            thisModName = strtrim(thisModName);

            PointsProj = h5read(h5name, ['/' thisModName '/PointsProj']);
            theseVals = PointsProj(:,3);
            thisMax(thisGroupIndex, ii) = max(theseVals);
            thisMin(thisGroupIndex, ii) = min(theseVals);
        end
    catch
    end
end



