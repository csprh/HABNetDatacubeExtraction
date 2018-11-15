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
BimonthlyAverageDirectory = 'BimonthlyAverageDirectory';
outDir = tmpStruct.confgData.outDir.Text;
confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
cd(outDir);
mkdir(BimonthlyAverageDirectory);
cd(BimonthlyAverageDirectory);


ChlDate1 = datenum('2019-01-01');
ChlDate2 = datenum('2003-01-01');
ChlDate1S = datestr(ChlDate1,29);
ChlDate2S = datestr(ChlDate2,29);

thisString = ['sensor=modisa&sdate=' ChlDate2S '&edate=' ChlDate1S '&dtype=L3b&addurl=1&results_as_file=1&search=*8D_CHL*'];
exeName  = [confgData.wgetStringBase ' -q --post-data="' thisString '" -O - https://oceandata.sci.gsfc.nasa.gov/api/file_search |' confgData.wgetStringBase ' -i -'];
system(exeName);