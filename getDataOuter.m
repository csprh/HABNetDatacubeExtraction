function getDataOuter
%% Top level code that loads config, loads .mat ground truth file,
%  searches for all relevant .nc granules (using fd_matchup.py and NASA's
%  CMR interface).  Datacubes are formed from all the local .nc granules
%
% USAGE:
%   getDataOuter
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
% Author Dr Paul Hill 26th June 2018

clear; close all;

if ismac
    tmpStruct = xml2struct('configHABmac.xml');
elseif isunix
    [dummy, thisCmd] = system('rpm --query centos-release');
    isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-5.1804.el7.centos.2.x86_64');
    if isUnderDesk == 1
        tmpStruct = xml2struct('configHABunderDesk.xml');
    else
        tmpStruct = xml2struct('configHAB.xml');
    end
elseif ispc
    % Code to run on Windows platform
else
    disp('Platform not supported')
end

%% load all config from XML file
confgData.inputFilename = tmpStruct.confgData.inputFilename.Text;
confgData.gebcoFilename = tmpStruct.confgData.gebcoFilename.Text;
confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
confgData.outDir = tmpStruct.confgData.outDir.Text;
confgData.distance1 = str2double(tmpStruct.confgData.distance1.Text);
confgData.resolution = str2double(tmpStruct.confgData.resolution.Text);
confgData.numberOfDaysInPast = str2double(tmpStruct.confgData.numberOfDaysInPast.Text);
confgData.numberOfSamples = str2double(tmpStruct.confgData.numberOfSamples.Text);
confgData.mods = tmpStruct.confgData.Modality;

system(['rm ' confgData.outDir '*.h5']);
load(confgData.inputFilename);
if confgData.numberOfSamples == -1;   confgData.numberOfSamples = length(count2); end;

%% Loop through all samples in .mat Ground Truth File
outputIndex = 1;
for ii = 1: confgData.numberOfSamples %Loop through all the ground truth entries
    try
        if rem(ii,10) == 1        % Delete the .nc files
            wdelString = 'rm *.nc';  unix(wdelString);
        end
        
        inStruc.thisLat = latitude(ii);
        inStruc.thisLon = longitude(ii);
        
        if isLandGEBCO(inStruc, confgData);  continue;  end;
        inStruc.thisCount = count2(ii);
        inStruc.zoneHrDiff = timezone(inStruc.thisLon);
        % Adjust input time / date: Assume that the sample is taken at 11pm
        % FWC say their data is collected in daylight hours (mostly)
        inStruc.endTimeUTC = 23+inStruc.zoneHrDiff;
        inStruc.dayEnd = sample_date(ii);
        if inStruc.endTimeUTC > 24; inStruc.endTimeUTC = inStruc.endTimeUTC-24; inStruc.dayEnd=inStruc.dayEnd+1; end;
        inStruc.dayEndFraction = inStruc.dayEnd+inStruc.endTimeUTC/24;
        inStruc.dayStart = inStruc.dayEnd - confgData.numberOfDaysInPast;
        inStruc.dayStartS = str(inStruc.dayStart,29);
        inStruc.dayEndS = datestr(inStruc.dayEnd,29);
        inStruc.UTCTime = sprintf('T%02d:00:00Z', inStruc.endTimeUTC);
        
        thisName = num2str(outputIndex);
        outputIndex = outputIndex+1;
        inStruc.h5name = [confgData.outDir 'flor' thisName '.h5'];
        if exist(inStruc.h5name, 'file')==2;  delete(inStruc.h5name);  end
        %Put images, count, dates and deltadates into output .H5 file
        hdf5write(inStruc.h5name,['/thisCount'],inStruc.thisCount);
        hdf5write(inStruc.h5name,['/dayEndFraction'],inStruc.dayEndFraction, 'WriteMode','append');
        getModData(inStruc, confgData);
    catch        
    end
end

function getModData(inStruc, confgData)
%% getModData in Data Retrieval Over the ground Truth Datapoints
%  Adds extracted information to one H5 file per datapoint in ground truth
%
% USAGE:
%   getModData(inStruc, confgData)
% INPUT:
%   inStruc - Contains all the input parameters for the function
%   confgData - Configuration information extracted from XML
% OUTPUT:
%   - 
numberOfMods = length(confgData.mods);
thisLat = inStruc.thisLat;
thisLon = inStruc.thisLon;
dayStartS = inStruc.dayStartS;
UTCTime = inStruc.UTCTime;
dayEndS = inStruc.dayEndS;

%% Loop through all the modulations
for modIndex = 1:numberOfMods
    
    thisMod = confgData.mods{modIndex}.Text;
    subMods = strsplit(thisMod,'-');
    
    if strcmp(subMods{1},'gebco')
        [elevationIm elevationPoints] = getGEBCOData(confgData, thisLat, thisLon);
        addToH5(inStruc.h5name, thisMod, elevationIm, 0, 0, elevationPoints);
        continue;
    end
    % product suites are either oc, iop or sst
    % sensors are either modisa,modist,viirsn,goci,meris,czcs,octs or 'seawifs'
    % sst: sstref, sst4, sst 1Km resolution for all sst
    % Search for "granules" at a particular lat, long and date range (output goes in Output.txt)
    exeName = ['python  fd_matchup.py --data_type=' subMods{1} ' --sat=' subMods{2} ' --slat=' num2str(thisLat) ' --slon=' num2str(thisLon) ' --stime=' dayStartS UTCTime ' --etime=' dayEndS UTCTime];
    system(exeName);
    
    %% Loop through .nc files, veryify and download / extract
    fid = fopen('Output.txt');   tline = fgetl(fid);
    indInput = 1;  clear thisInput; clear thisList;
    while ischar(tline)
        [filepath,thisName,ext] = fileparts(tline);
        if thisName(end) ~= '4'   %ignore SST4
            thisDate=julian2time(thisName(2:14));
            thisInput{indInput}.line = tline;
            thisInput{indInput}.date = thisDate;
            thisInput{indInput}.deltadate = inStruc.dayEndFraction-thisDate;
            indInput = indInput + 1;
        end
        tline = fgetl(fid);
    end
    
    fclose(fid);
    %% Re-order the list of found data
    for iii = 1: length(thisInput); thisList(iii) = thisInput{iii}.deltadate; end;
    [sorted sortIndex] = sort(thisList);
    
    if strcmp(subMods{1},'sst'); sortIndex = sortIndex(1);  end % Needed to prevent issues with SST4
    %% Loop through previous times and extract images and points from .nc files
    % iyyyydddhhmmss.L2_rrr_ppp,
    % where i is the instrument identifier  yyyydddhhmmss
    clear theseDates theseDeltaDates theseImages;
    thesePointsOutput = [];
    for iii = 1:length(sortIndex)
        thisIndex = sortIndex(iii);
        thisLine = thisInput{thisIndex}.line;
        thisDate = thisInput{thisIndex}.date;
        thisDeltaDate = thisInput{thisIndex}.deltadate;
        [filepath,name,ext] = fileparts(thisLine);
        fileName = [name ext];
        
        %wget file if it hasn't previously been downloaded
        if exist(fileName, 'file')~=2;
            wgetString = [confgData.wgetStringBase ' ' thisLine];
            unix(wgetString);
        end
        
        [theseImages{iii} thesePoints] = getData(fileName,  thisLat, thisLon, confgData.distance1, confgData.resolution, ['/geophysical_data/' subMods{3}]);
        theseDates{iii} = thisDate;
        theseDeltaDates{iii} = thisDeltaDate;
        thesePointsNew = [thesePoints ones(size(thesePoints,1),1)*thisDeltaDate];
        thesePointsOutput = [thesePointsOutput; thesePointsNew];
    end
    
    addToH5(inStruc.h5name, thisMod, theseImages, theseDates, theseDeltaDates, thesePointsOutput);
    h5disp(inStruc.h5name);
end
% Zip up the data and delete the original
gzip(inStruc.h5name);
system(['rm ' confgData.outDir '*.h5']);

function t=julian2time(str)
%% julian2time takes the julian day of the year contained in the .nc granule
%  and converts it to integer datenum (as output by datestr).
%  convert NASA yyyydddHHMMSS to datenum
%  ddd starts with 1 (therefore we have to take 1 away
%
% USAGE:
%   t=julian2time(str)
% INPUT:
%   str - input string containing time in julian format
% OUTPUT:
%   t - output time
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;

function addToH5(h5name, thisMod, theseImages, theseDates, theseDeltaDates, thesePointsOutput)
%% add Ims, theseDates, theseDeltaDates and Points to output H5 file
%
% USAGE:
%   addToH5(h5name, thisMod, theseImages, theseDates, theseDeltaDates, thesePointsOutput)
% INPUT:
%   h5name - name of H5 name to be output
%   theseImages - Cell array of output binned images (for this modality)
%   theseDates - The actual capture dates of the points and images output
%   theseDeltaDates - The delta dates (difference from capture date) of the points and images output
%   thesePointsOutput - 4D Array of points output
% OUTPUT:
%   - 
hdf5write(h5name,['/' thisMod  '/Ims'],theseImages, 'WriteMode','append');
hdf5write(h5name,['/' thisMod  '/theseDates'],theseDates, 'WriteMode','append');
hdf5write(h5name,['/' thisMod  '/theseDeltaDates'],theseDeltaDates, 'WriteMode','append');
hdf5write(h5name,['/' thisMod  '/Points'],thesePointsOutput, 'WriteMode','append');

