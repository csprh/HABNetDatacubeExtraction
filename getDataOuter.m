function getDataOuter;
clear; close all;

mac = ismac;

if mac ==1 
    filename = '../../WORK/florida_2013-2016';
    wgetStringBase = '/usr/local/bin/wget ';
    outDir = '../../WORK/HAB/florida1/';
else
    filename = '../work/florida_2013-2016v2';
    wgetStringBase = '/usr/bin/wget ';
    outDir = '/mnt/storage/scratch/csprh/HAB/florida1/'
end


distance1 = 50000;     resolution = 2000;
numberOfDaysInPast = 3;
load(filename);
lenData = length(count2);
for ii = 1: 2 %Loop through all the ground truth entries
   try 
    thisLat = latitude(ii);
    thisLon = longitude(ii);
    thisCount = count2(ii);
    %thisLat = 51.454513;
    %thisLon = -2.58791;
  
    %thisLat = 51.5074;
    %thisLon = 0.1278;
    
    inputDay = sample_date(ii)+0.5;  %  'datenum' date from 0-Jan-0000 (Gregorian)
    dayStart = inputDay-numberOfDaysInPast;
    dayEnd = inputDay+1;
    dayStartS = datestr(dayStart,29);
    dayEndS = datestr(dayEnd,29);
    
    % Search for "granules" at a particular lat, long and date range
    % (output goes in Output.txt)
    exeName = ['python  fd_matchup.py --data_type=oc --sat=modisa ' '--slat=' num2str(thisLat) ' --slon=' num2str(thisLon) ' --stime=' dayStartS 'T12:00:00Z --etime=' dayEndS 'T12:00:00Z'];
    system(exeName);
    
    % Extract OC lines from output
    fid = fopen('Output.txt');   tline = fgetl(fid);
    indInput = 1; clear OCLines; clear thisInput; clear thisList;
    while ischar(tline)
        [filepath,name,ext] = fileparts(tline);
        thisDate=julian2time(name(2:14));
        endOfLine = tline(end-4:end);
        if strcmp(endOfLine,'OC.nc')
            thisInput{indInput}.line = tline;
            thisInput{indInput}.date = thisDate;
            thisInput{indInput}.deltadate = thisDate-inputDay;
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
    % iyyyydddhhmmss.L2_rrr_ppp, 
    % where i is the instrument identifier  yyyydddhhmmss 
    clear theseDates theseDeltaDates theseImages;
    thesePointsOutput = [];
    for iii = 1:length(historicalIndex)
        thisIndex = historicalIndex(iii);
        thisLine = thisInput{thisIndex}.line;
        thisDate = thisInput{thisIndex}.date;
        thisDeltaDate = thisInput{thisIndex}.deltadate;
        wgetString = [wgetStringBase thisLine];
        unix(wgetString);
        [filepath,name,ext] = fileparts(thisLine);
        fileName = [name ext];       
        thisVar = 'chlor_a';
        [theseImages{iii} thesePoints] = getData(fileName,  thisLat, thisLon, distance1, resolution, ['/geophysical_data/' thisVar]);
        theseDates{iii} = thisDate;
        theseDeltaDates{iii} = thisDeltaDate;
        thesePointsNew = [thesePoints ones(size(thesePoints,1),1)*thisDeltaDate];
        thesePointsOutput = [thesePointsOutput; thesePointsNew];
        %Put image and date into structure
        wdelString = 'rm *.nc';
        unix(wdelString);  
    end



    
thisName = num2str(ii);

h5name = [outDir 'flor' thisName '.h5']

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

function t=julian2time(str)
% convert NASA yyyydddHHMMSS to datenum
ddd=str2double(str(5:7));
jan1=[str(1:4),'0101',str(8:13)];  % day 1 
t=datenum(jan1,'yyyymmddHHMMSS')+ddd-1;
