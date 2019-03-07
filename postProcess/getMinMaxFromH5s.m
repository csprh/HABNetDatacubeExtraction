function [thisMax, thisMin] = getMinMaxFromH5s(filenameBase)
%% This Code loops through al the h5 output files and generates
%% The maximum and minimum values of the modalities
% USAGE:
%   groupMinMax = getMinMaxFromH5s(filenameBase)
% INPUT:
%   filenameBase
% OUTPUT:
%   groupMinMax
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill March 2019
close all;

h5files=dir([filenameBase '*.h5.gz']);
numberOfH5s=size(h5files,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop through all the ground truth entries%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1: numberOfH5s
    try
        %% Process input h5 file
        system(['rm ' filenameBase '*.h5']);
        gzh5name = [filenameBase h5files(ii).name];
        gunzip(gzh5name);
        h5name = gzh5name(1:end-3);
        thisH5Info = h5info(h5name);
        thisH5Groups = thisH5Info.Groups;
        numberOfGroups = size(thisH5Groups,1);
        if ii == 1
            % Initalise
            thisMax = ones(numberOfGroups-1,numberOfH5s)*NaN;
            thisMin = ones(numberOfGroups-1,numberOfH5s)*NaN;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%Loop through all modalities              %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for groupIndex = 2: numberOfGroups
            thisGroupIndex = groupIndex-1;
            thisGroupName = thisH5Groups(groupIndex).Name;
            Points = h5read(h5name, [thisGroupName '/Points']);
            theseVals = Points(:,3);
            thisMax(thisGroupIndex, ii) = max(theseVals);
            thisMin(thisGroupIndex, ii) = min(theseVals);
            
            
        end
    catch
    end
end



