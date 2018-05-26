function getDataOuter;
%% Top level code that loads config, loads .mat ground truth file, 
%  searches for all relevant .nc granules (using fd_matchup.py and NASA's
%  CMR interface).  Datacubes are formed from all the local .nc granules

clear; close all;

mac = ismac;

if mac ==1
    tmpStruct = xml2struct('configHABmac.xml');
else
    tmpStruct = xml2struct('configHAB.xml');
end

%% load all config from XML file
confgData.inputFilename = tmpStruct.confgData.inputFilename.Text;
confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
confgData.outDir = tmpStruct.confgData.outDir.Text;
confgData.distance1 = str2double(tmpStruct.confgData.distance1.Text);
confgData.resolution = str2double(tmpStruct.confgData.resolution.Text);
confgData.numberOfDaysInPast = str2double(tmpStruct.confgData.numberOfDaysInPast.Text);
confgData.numberOfSamples = str2double(tmpStruct.confgData.numberOfSamples.Text);

load(confgData.inputFilename);
if confgData.numberOfSamples == -1;   confgData.numberOfSamples = length(count2); end;

%% Loop through all samples in .mat Ground Truth File
for ii = 1: confgData.numberOfSamples %Loop through all the ground truth entries
    try
        thisLat = latitude(ii);
        thisLon = longitude(ii);
        thisCount = count2(ii);
        zoneHrDiff = timezone(thisLon); 
        endTimeUTC = 12+zoneHrDiff; % Assume that the sample is taken at midday
        dayEnd = sample_date(ii);
        dayEndFraction = dayEnd+endTimeUTC/24;
        dayStart = dayEnd - confgData.numberOfDaysInPast;   
        dayStartS = datestr(dayStart,29);
        dayEndS = datestr(dayEnd,29);
        UTCTime = sprintf('T%02d:00:00Z', endTimeUTC);
        
        % Search for "granules" at a particular lat, long and date range (output goes in Output.txt)
        exeName = ['python  fd_matchup.py --data_type=oc --sat=modisa ' '--slat=' num2str(thisLat) ' --slon=' num2str(thisLon) ' --stime=' dayStartS UTCTime ' --etime=' dayEndS UTCTime];
        system(exeName);
        
        % Loop through .nc files, veryify and download / extract
        fid = fopen('Output.txt');   tline = fgetl(fid);
        indInput = 1; clear OCLines; clear thisInput; clear thisList;
        while ischar(tline)
            [filepath,thisName,ext] = fileparts(tline);
            thisDate=julian2time(thisName(2:14));
            endOfLine = tline(end-4:end);
            if strcmp(endOfLine,'OC.nc')
                thisInput{indInput}.line = tline;
                thisInput{indInput}.date = thisDate;
                thisInput{indInput}.deltadate = thisDate-dayEndFraction;
                indInput = indInput + 1;
            end
            tline = fgetl(fid);
        end
        
        for iii = 1: length(thisInput)
            thisList(iii) = thisInput{iii}.deltadate;
        end
        [sorted sortIndex] = sort(thisList);
        
        closeest = find(min(abs(thisList))==abs(thisList));
        closeestIndex = find(sortIndex==closeest);
        historicalIndex = fliplr(sortIndex(1:closeestIndex));
        %% Loop through previous times and extract images and points from .nc files
        % iyyyydddhhmmss.L2_rrr_ppp,
        % where i is the instrument identifier  yyyydddhhmmss
        clear theseDates theseDeltaDates theseImages;
        thesePointsOutput = [];
        for iii = 1:length(historicalIndex)
            thisIndex = historicalIndex(iii);
            thisLine = thisInput{thisIndex}.line;
            thisDate = thisInput{thisIndex}.date;
            thisDeltaDate = thisInput{thisIndex}.deltadate;
            wgetString = [confgData.wgetStringBase ' ' thisLine];
            unix(wgetString);
            [filepath,name,ext] = fileparts(thisLine);
            fileName = [name ext];
            thisVar = 'chlor_a';
            [theseImages{iii} thesePoints] = getData(fileName,  thisLat, thisLon, confgData.distance1, confgData.resolution, ['/geophysical_data/' thisVar]);
            theseDates{iii} = thisDate;
            theseDeltaDates{iii} = thisDeltaDate;
            thesePointsNew = [thesePoints ones(size(thesePoints,1),1)*thisDeltaDate];
            thesePointsOutput = [thesePointsOutput; thesePointsNew];
            % Delete the .nc file
            wdelString = 'rm *.nc';
            unix(wdelString);
        end
        
        thisName = num2str(ii);
        h5name = [confgData.outDir 'flor' thisName '.h5']
        
        %Put images, count, dates and deltadates into output .H5 file
        hdf5write(h5name,['/thisCount'],thisCount);
        hdf5write(h5name,['/inputDay'],inputDay, 'WriteMode','append');
        hdf5write(h5name,['/' thisVar '/Ims'],theseImages, 'WriteMode','append');
        hdf5write(h5name,['/' thisVar '/theseDates'],theseDates, 'WriteMode','append');
        hdf5write(h5name,['/' thisVar '/theseDeltaDates'],theseDeltaDates, 'WriteMode','append');
        hdf5write(h5name,['/' thisVar '/thesePointsOutput'],thesePointsOutput, 'WriteMode','append');
        
        h5disp(h5name);
        fclose(fid);
    catch
    end
end

%% julian2time takes the julian day of the year contained in the .nc granule
%  and converts it to integer datenum (as output by datestr).
function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
% ddd starts with 1 (therefore we have to take 1 away
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
