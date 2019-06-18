function downloadModisAChlrv2
%% Function that integrates all the Chloraphyl data on a bi-monthly basis
% from level-3 8 day products
%
% USAGE:
%   downloadModisAChlrv2
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
%
% TODO!
% This code is very inefficient as it downloads all the global data for two
% months multiple times.  Also, it should be quantised / rasterised to
% reduce the amount of data in the outpuot .h5 files
% 
% NOTES:
% Only modis aqua is used as modis terra is degrading in quality after
% about 2011.  

% Author Dr Paul Hill 26th Feb 2019
close all; clear all;
addpath('../.');
if ismac
    rmcommand = 'rm ';
    tmpStruct = xml2struct('../configHABmac.xml');
elseif isunix
    rmcommand = 'rm ';
    [~, thisCmd] = system('rpm --query centos-release');
    isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-6.1810.2.el7.centos.x86_64');
    if isUnderDesk == 1
        tmpStruct = xml2struct('../configHABunderDesk.xml');
    else
        tmpStruct = xml2struct('../configHAB.xml');
    end
elseif ispc
    % Code to run on Windows platform
    tmpStruct = xml2struct('../configHAB_win.xml');
    rmcommand = ['del ' pwd '\' ];
else
    disp('Platform not supported')
end
%% load all config from XML file
BimonthlyAverageDirectory = 'BimonthlyAverageDirectory';
outDir = [tmpStruct.confgData.trainDir.Text BimonthlyAverageDirectory];
wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
downloadDir = tmpStruct.confgData.downloadFolder.Text;
mkdir(outDir);


%Get max/min (original excel file)
%lattitude Min/Max = 24, 40.73333
%longitude Min/Max = -76.65694 -87.51778
%Get max/min (original 50k mat file)
%lattitude Min/Max = 24.4455, 30.7012
%longitude Min/Max = -79.9940  -87.9453

%Get max/min (original 5k mat file) USED!
%lattitude Min/Max = 24.1864, 30.7012
%longitude Min/Max = -79.9748  -87.9453

%Loop through dates 2003 to 2019
%Extract for bi-monthly range
%For each range, extract


% FROM MASDAR Stuff
%lonMinMax = [-87.9897 -79.6979];
%latMinMax = [24.0416 30.2500];

ind = 0;
latMinMax = [24.0864 30.8012];
lonMinMax = [-88.0453 -79.8748];
dayStartS = '2003-11-06';
dayEndS = '2019-01-01';
biMonthlyOffset = 61; %(two months approx)
dayStart = datenum(dayStartS);
dayEnd = datenum(dayEndS);
zoneHrDiff = timezone(mean(lonMinMax));
[rmcommand, pythonStr, tmpStruct] = getHABConfig;
thisDay = dayStart;
removeFreq = 300;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop from start day to end day%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OO = [];
while thisDay <  dayEnd
    ind = ind +1;
    try

        if rem(ind,removeFreq) == 1 && ind>1       % Delete the .nc files (every tenth one)
                system(['rm ' downloadDir '*.nc']);
        end

        thisMod = 'oc-modisa-chlor_a';
        subMods = strsplit(thisMod,'-');

        UTCTime = sprintf('T%02d:00:00Z', zoneHrDiff);

        thisEndDay =  thisDay+biMonthlyOffset;
        thisDayS   =  datestr(thisDay,29);
        thisEndDayS = datestr(thisEndDay,29);
         
        pyOpt = [' --data_type=' subMods{1} ' --sat=' subMods{2} ' --slat=' num2str(mean(latMinMax)) ...
            ' --slon=' num2str(mean(lonMinMax)) ' --stime=' thisDayS UTCTime ' --etime=' thisEndDayS UTCTime];
        disp(['Searching granules for: --mod=',subMods{3}, pyOpt])
        exeName = [pythonStr ' ../fd_matchup.py', pyOpt,' > cmdOut.txt'];
        system(exeName);
        
        fid = fopen('Output.txt');
        tline = fgetl(fid);
        indInput = 1;  clear thisInput; clear thisList;
        while ischar(tline)
           [~,nc_name,~] = fileparts(tline);
           thisDate=julian2time(nc_name(2:14));
           thisInput(indInput).line = tline;
           thisInput(indInput).date = thisDate;
           indInput = indInput + 1;
        
           tline = fgetl(fid);
        end
        fclose(fid);
        disp(['Found ', num2str(length(thisInput)), ' granules.' ])
        
        numberOfNCs=length(thisInput);
        outputTriple = [];
        
        
        cluster = parcluster('local'); nworkers = cluster.NumWorkers;
        parfor (iii = 1:numberOfNCs,nworkers)
        %for (iii = 1:numberOfNCs)
           thisIndex = iii;
           thisLine = thisInput(thisIndex).line;
           thisDate = thisInput(thisIndex).date;

           [~,name,ext] = fileparts(thisLine);
           fileName = [downloadDir name ext];
        
           %wget file if it hasn't previously been downloaded
           if exist(fileName, 'file')~=2
            %In windows relative paths to wget will only run if the file
            %directory is local or if the network directory has been
            %mapped. Otherwise just copy wget.exe to the same path as the
            %.m files and modify the xml accordingly.
            wgetString = [wgetStringBase,' -nv', ' -P ',downloadDir, ' ', thisLine];
            disp(['Downloading granule ',num2str(thisIndex),' from ',thisLine,' ...'])
            system(wgetString);
           end

           lonDD = ncread(fileName, '/navigation_data/longitude'); lonDD = lonDD(:);
           latDD = ncread(fileName, '/navigation_data/latitude'); latDD = latDD(:);
           inVar = ncread(fileName, '/geophysical_data/chlor_a'); inVar = inVar(:);
  
           maxlt = max(lonDD);
           maxln = max(latDD);
           
           minlt = max(lonDD);
           minln = max(latDD);
           
           outMinMax = [minlt maxlt minln maxln];
           OO = [OO ;outMinMax];
            ind = (lonDD>=lonMinMax(1) & lonDD<=lonMinMax(2) & latDD>=latMinMax(1) &latDD<=latMinMax(2));
            
            outLat = latDD(ind);
            outLon = lonDD(ind);
            outVal = inVar(ind);
            thisTriple = [outLat outLon outVal];
            outputTriple = [thisTriple; outputTriple];
        end
        
        
        h5name = [outDir '/Bimonthly_Chlor_a_' num2str(thisDay) '_' num2str(thisEndDay) '.h5'];
        if exist(h5name, 'file')==2;  delete(h5name);  end
        fid = H5F.create(h5name);
        H5F.close(fid);
        hdf5write(h5name,'/biMonthTriple', outputTriple, 'WriteMode','append');
        h5writeatt(h5name, '/','thisDayS', thisDayS);
        h5writeatt(h5name, '/','thisEndDayS', thisEndDayS);
        h5writeatt(h5name,'/', 'thisDay', thisDay);
        h5writeatt(h5name, '/','thisEndDay', thisEndDay);

        thisDay = thisDay+1;
    catch err
        logErr(err,num2str(thisDay));
        thisDay = thisDay+1;
    end
end

function logErr(e,strIden)
    fileID = fopen('errors.txt','at');
    identifier = ['Error procesing sample ',strIden, ' at ', datestr(now)];
    text = [e.identifier, '::', e.message];
    fprintf(fileID,'%s\n',identifier);
    fprintf(fileID,'%s\n',text);
    fclose(fileID);
    
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

