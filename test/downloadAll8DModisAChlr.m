function downloadAll8DModisAChlr
%% Function that integrates all the Chloraphyl data on a bi-monthly basis
% from level-3 8 day products
%
% USAGE:
%   downloadAll8DModisAChlr
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
outDir = [tmpStruct.confgData.outDir.Text BimonthlyAverageDirectory];
confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
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

ind = 0;
latMinMax = [24.0864 30.8012];
lonMinMax = [-88.0453 -79.8748];
dayStartS = '2003-11-06';
dayEndS = '2019-01-01';
biMonthlyOffset = 61; %(two months approx)
dayStart = datenum(dayStartS);
dayEnd = datenum(dayEndS);

thisDay = dayStart;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Loop from start day to end day%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while thisDay <  dayEnd
    ind = ind +1;
    try

        system([rmcommand downloadDir '*.nc']);
        thisEndDay = thisDay+biMonthlyOffset;
        thisDayS   =   datestr(thisDay,29);
        thisEndDayS = datestr(thisEndDay,29);
         
        postDataOpts = ['sensor=modisa&sdate=' thisDayS '&edate=' thisEndDayS ...
            '&dtype=L3b&addurl=1&results_as_file=1&search=A*8D_CHL.nc'];
        
        exeName  = [confgData.wgetStringBase ' -q --post-data="' postDataOpts ...
            '" -O - https://oceandata.sci.gsfc.nasa.gov/api/file_search |' confgData.wgetStringBase ' -P ',downloadDir, ' -i -'];
 
        system(exeName);
        
        NCfiles=dir([downloadDir '*.nc']);
        numberOfNCs=size(NCfiles,1);
        outputTriple = [];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%Loop through the NCs          %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for ii = 1: numberOfNCs
            
            %% Process input h5 file
            ncName = NCfiles(ii).name;
            A = h5read([downloadDir ncName],'/level-3_binned_data/chlor_a');
            B = h5read([downloadDir ncName],'/level-3_binned_data/BinList');
            z = double(A.sum_squared);
            bins = B.bin_num;
            [lat,lon] = binind2latlon(bins);
            ind = (lon>=lonMinMax(1) & lon<=lonMinMax(2) & lat>=latMinMax(1) &lat<=latMinMax(2));
            
            outLat = lat(ind);
            outLon = lon(ind);
            outVal = z(ind);
            thisTriple = [outLat outLon outVal];
            outputTriple = [thisTriple; outputTriple];
        end
        
        h5name = [outDir '/BimonthLy_Chlor_a_' num2str(thisDay) '_' num2str(thisEndDay) '.h5'];
        if exist(h5name, 'file')==2;  delete(h5name);  end
        fid = H5F.create(h5name);
        H5F.close(fid);
        hdf5write(h5name'/biMonthTriple', outputTriple, 'WriteMode','append');
        h5writeatt(h5name, '/','thisDayS', thisDayS);
        h5writeatt(h5name, '/','thisEndDayS', thisEndDayS);
        h5writeatt(h5namep,'/', 'thisDay', thisDay);
        h5writeatt(h5name, '/','thisEndDay', thisEndDay);

        thisDay = thisDay+8;
    catch err
        logErr(err,num2str(thisDay));
        thisDay = thisDay+8;
    end
end

function logErr(e,strIden)
    fileID = fopen('errors.txt','at');
    identifier = ['Error procesing sample ',strIden, ' at ', datestr(now)];
    text = [e.identifier, '::', e.message];
    fprintf(fileID,'%s\n',identifier);
    fprintf(fileID,'%s\n',text);
    fclose(fileID);
