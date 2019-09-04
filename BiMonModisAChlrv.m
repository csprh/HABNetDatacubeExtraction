function BiMonModisAChlrv
%% Function that integrates all the Chloraphyl data on a bi-monthly basis
%
% USAGE:
%   BiMonModisAChlrv
% INPUT:
%   -
% OUTPUT:
%   -
% THE UNIVERSITY OF BRISTOL: HAB PROJECT
%
% This code loops through all oc-modisa-chlor_a MODIS sources and outputs
% them into H5 files for the range required (Florida / Gulf)
%
%
% NOTES:
% Only modis aqua is used as modis terra is degrading in quality after
% about 2011.

% Author Dr Paul Hill July 2019
close all; clear all;
GULF = 1;

if ismac
    rmcommand = 'rm ';
    tmpStruct = xml2struct('configHABmac.xml');
elseif isunix
    rmcommand = 'rm ';
    [~, thisCmd] = system('rpm --query centos-release');
    isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-6.1810.2.el7.centos.x86_64');
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
    tmpStruct = xml2struct('configHAB_win.xml');
    rmcommand = ['del ' pwd '\' ];
else
    disp('Platform not supported')
end
%% load all config from XML file
BimonthlyAverageDirectory = 'BimonthlyAverageDirectory';
DailyAverageDirectory = 'DailyAverageDirectory';
outDirDaily = [tmpStruct.confgData.trainDir.Text DailyAverageDirectory];
outDirBimonth = [tmpStruct.confgData.trainDir.Text BimonthlyAverageDirectory];
wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
downloadDir = tmpStruct.confgData.downloadFolder.Text;
mkdir(tmpStruct.confgData.trainDir.Text);
mkdir(outDirDaily);
mkdir(outDirBimonth);
mkdir(downloadDir);

%lonMinMax = [-87.9897 -79.6979];
%latMinMax = [24.0416 30.2500];

ind = 0;

if GULF == 1
    latMinMax =  [23 30.42];
    lonMinMax =  [47.69 58]; %Gulf
else
    latMinMax = [24.0864 30.8012];
    lonMinMax = [-88.0453 -79.8748];
end
latGrid = 0.05;
lonGrid = 0.05;
latLonRangeS = [' --slat=' num2str(latMinMax(1)) ' --elat=' num2str(latMinMax(2)) ' --slon=' num2str(lonMinMax(1)) ' --elon=' num2str(lonMinMax(2))];

doDailyFirst = 1;

dayStartS = '2002-10-24';
dayEndS = '2019-03-03';
biMonthlyOffset = 61; %(two months approx)
dailyOffset = 1;
dayStart = datenum(dayStartS);
dayEnd = datenum(dayEndS);
zoneHrDiff = timezone(mean(lonMinMax));
[rmcommand, pythonStr, tmpStruct] = getHABConfig;
thisDay = dayStart;
removeFreq = 500;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop from start day to end day%%%
%%Load each day aqua chlor_a and%%%
%%Output in new H5              %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if doDailyFirst == 1
    while thisDay <  dayEnd
        ind = ind +1;
        try
            
            if rem(ind,removeFreq) == 1 && ind>1       % Delete the .nc files (every tenth one)
                system(['rm ' downloadDir '*.nc']);
            end
            
            thisMod = 'oc-modisa-chlor_a';
            subMods = strsplit(thisMod,'-');
            
            UTCTime = sprintf('T%02d:00:00Z', zoneHrDiff);
            
            thisEndDay =  thisDay+dailyOffset;
            thisDayS   =  datestr(thisDay,29);
            thisEndDayS = datestr(thisEndDay,29);
            
            pyOpt = [' --data_type=' subMods{1} ' --sat=' subMods{2} latLonRangeS ' --stime=' thisDayS UTCTime ' --etime=' thisEndDayS UTCTime];
            disp(['Searching granules for: --mod=',subMods{3}, pyOpt])
            exeName = [pythonStr ' fd_matchup.py', pyOpt,' > cmdOut.txt'];
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
            
            for iii = 1:numberOfNCs
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
                
                thisInd = (lonDD>=lonMinMax(1) & lonDD<=lonMinMax(2) & latDD>=latMinMax(1) &latDD<=latMinMax(2));
                
                outLat = latDD(thisInd);  outLon = lonDD(thisInd);
                outVal = inVar(thisInd);  nanInd = isnan(outVal);
                outLat = outLat(~nanInd); outLon = outLon(~nanInd);
                outVal = outVal(~nanInd);
                
                thisTriple = [outLat outLon outVal];
                outputTriple = [thisTriple; outputTriple];
            end
            LatCntrs = latMinMax(1):latGrid:latMinMax(2);
            LonCntrs = lonMinMax(1):lonGrid:lonMinMax(2);
            
            [LAT, LON] = meshgrid(LatCntrs,LonCntrs);
            
            LatCntrs = latMinMax(1)-latGrid:latGrid:latMinMax(2)+latGrid;
            LonCntrs = lonMinMax(1)-lonGrid:lonGrid:lonMinMax(2)+lonGrid;
            % Count number of datapoints in bins.  Then accumulate their values
            cnt = hist3([outputTriple(:,1), outputTriple(:,2)], {LatCntrs LonCntrs});
            weightsH = hist2w([outputTriple(:,1), outputTriple(:,2)], outputTriple(:,3) ,LatCntrs,  LonCntrs);
            
            % We must then reduce the size of the output to get rid of the edge bins
            weightsH = weightsH(2:end-1,2:end-1);
            cnt = cnt(2:end-1,2:end-1);
            %If cnt is 0 then no datapoints in bin
            %If weightsH is NaN then no datapoint
            %Normalise output and set no data to -1 (for tensorflow etc.)
            ign = ((cnt==0)|(isnan(weightsH)));
            outputIm = weightsH./cnt;
            
            outputIm(ign) = 0;
            
            h5name = [outDirDaily '/Daily_Chlor_a_' num2str(thisDay) '_' num2str(thisEndDay) '.h5'];
            if exist(h5name, 'file')==2;  delete(h5name);  end
            fid = H5F.create(h5name);
            H5F.close(fid);
            hdf5write(h5name,'/Chlor_a', outputIm, 'WriteMode','append');
            hdf5write(h5name, '/lon', LON , 'WriteMode','append');
            hdf5write(h5name, '/lat', LAT , 'WriteMode','append');
            
            thisDay = thisDay+1;
        catch err
            logErr(err,num2str(thisDay));
            thisDay = thisDay+1;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop from start day to end day%%%
%%and integrate bimonthly stuff %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
thisDay = dayStart;
while thisDay <  dayEnd
    
    clear outputIm LON LAT
    for ii = 1: biMonthlyOffset
        h5name = [outDirDaily '/Daily_Chlor_a_' num2str(thisDay+ii-1) '_' num2str(thisDay+ii) '.h5'];
        
        try
            outputIm(:,:,ii) = h5read(h5name,'/Chlor_a');
            LON = h5read(h5name,'/lon');
            LAT = h5read(h5name,'/lat');
        catch
            %Do Nowt
        end
        
    end
    
    outputIm(outputIm==0) = NaN;
    outputIm = nanmean(outputIm,3);
    
    h5name = [outDirBimonth '/Bimonthly_Chlor_a_' num2str(thisDay) '_' num2str(thisDay+biMonthlyOffset) '.h5'];
    if exist(h5name, 'file')==2;  delete(h5name);  end
    fid = H5F.create(h5name);
    H5F.close(fid);
    hdf5write(h5name,'/Chlor_a', outputIm, 'WriteMode','append');
    hdf5write(h5name, '/lon', LON , 'WriteMode','append');
    hdf5write(h5name, '/lat', LAT , 'WriteMode','append');
    thisDay = thisDay+1;
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

