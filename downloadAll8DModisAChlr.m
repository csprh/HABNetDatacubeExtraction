if ismac
    tmpStruct = xml2struct('configHABmac.xml');
elseif isunix
    [dummy, thisCmd] = system('rpm --query centos-release');
    isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-6.1810.2.el7.centos.x86_64');
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
BimonthlyAverageDirectory = 'BimonthlyAverageDirectory';
outDir = [tmpStruct.confgData.outDir.Text BimonthlyAverageDirectory];
confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;

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
latMinMax = [24.1864 30.7012]; 	
lonMinMax = [-87.9453 -79.9748];
dayStartS = '2003-01-01';
dayEndS = '2019-01-01';
dayStart = datenum(dayStartS);
dayEnd = datenum(dayEndS);

thisDay = dayStart;
while thisDay <  dayEnd
    ind = ind +1;
    wdelString = 'rm *.nc';  unix(wdelString);
    thisEndDay = thisDay+61;
    thisDayS = datestr(thisDay,29);
    thisEndDayS = datestr(thisEndDay,29);
    
    thisString = ['sensor=modisa&sdate=' thisDayS '&edate=' thisEndDayS '&dtype=L3b&addurl=1&results_as_file=1&search=A*8D_CHL.nc'];
    exeName  = [confgData.wgetStringBase ' -q --post-data="' thisString '" -O - https://oceandata.sci.gsfc.nasa.gov/api/file_search |' confgData.wgetStringBase ' -i -'];
    system(exeName);
 
    NCfiles=dir('*.nc');
    numberOfNCs=size(NCfiles,1);
    outputTriple = [];
    for ii = 1: numberOfNCs

    ii
        %% Process input h5 file

        ncName = [outDir '/' NCfiles(ii).name];
        A = h5read(ncName,'/level-3_binned_data/chlor_a');
        B = h5read(ncName,'/level-3_binned_data/BinList');
        z = double(A.sum_squared);
        bins = B.bin_num;
        [lat,lon] = binind2latlon(bins);
        ind = lon>=lonMinMax(1) & lon<=lonMinMax(2) & lat>=latMinMax(1) &lat<=latMinMax(2);
        
        outLat = lat(ind);
        outLon = lon(ind);
        outVal = z(ind);
        thisTriple = [outLat outLon outVal];
        outputTriple = [thisTriple; outputTriple]; 
    end

    
    
    h5name = [outDir '/BimonthLy_Chlor_a_' num2str(thisDay) '_' num2str(thisEndDay) '.h5'];
    
    fid = H5F.create(h5name);
    H5F.close(fid);
    hdf5write(h5name,['/biMonthTriple'],outputTriple, 'WriteMode','append');
    hdf5write(h5name,['/thisDayS'],thisDayS, 'WriteMode','append');
    hdf5write(h5name,['/thisEndDayS'],thisEndDayS, 'WriteMode','append');
    hdf5write(h5name,['/thisDay'],thisDay, 'WriteMode','append');
    hdf5write(h5name,['/thisEndDay'],thisEndDay, 'WriteMode','append');
    % get list of downloaded .nc 
    % loop through
    %   open .nc
    thisDay = thisDay+8;    
end

