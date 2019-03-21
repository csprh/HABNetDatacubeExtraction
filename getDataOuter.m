function getDataOuter
    %% Top level code that loads xml config, loads .mat ground truth file,
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
    % Updated March 2019 PRH
    % Updates for WIN compatibility: JVillegas 21 Feb 2019, Khalifa University
    clear; close all;

    [rmcommand, pythonStr, tmpStruct] = getHABConfig;

    %% load all config from XML file
    confgData.inputFilename = tmpStruct.confgData.inputFilename.Text;
    confgData.gebcoFilename = tmpStruct.confgData.gebcoFilename.Text;
    confgData.wgetStringBase = tmpStruct.confgData.wgetStringBase.Text;
    confgData.outDir = tmpStruct.confgData.outDir.Text;
    confgData.downloadDir = tmpStruct.confgData.downloadFolder.Text; 
    confgData.distance1 = str2double(tmpStruct.confgData.distance1.Text);
    confgData.resolution = str2double(tmpStruct.confgData.resolution.Text);
    confgData.numberOfDaysInPast = str2double(tmpStruct.confgData.numberOfDaysInPast.Text);
    confgData.numberOfSamples = str2double(tmpStruct.confgData.numberOfSamples.Text);
    confgData.mods = tmpStruct.confgData.Modality;

    system([rmcommand confgData.outDir '*.h5']);
    load(confgData.inputFilename); 
    if confgData.numberOfSamples == -1;   confgData.numberOfSamples = length(count2); end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Loop through all samples in .mat Ground Truth File %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    startIndex = 1;
    outputIndex = startIndex;
    for ii = startIndex: confgData.numberOfSamples %Loop through all the ground truth entries
         try
            if rem(ii,10) == 1 && ii>startIndex       % Delete the .nc files (every tenth one)
                system([rmcommand confgData.downloadDir '*.nc']);
            end

            inStruc.ii = ii;
            inStruc.thisLat = latitude(ii);
            inStruc.thisLon = longitude(ii);
            inStruc.dayEnd = sample_date(ii);
            inStruc.thisCount = count2(ii);
            
            fileName = ['Cube_' sprintf('%05d',outputIndex) '_' sprintf('%05d',ii) '_' num2str(sample_date(ii)) '.h5'];
            
            if isLandGEBCO(inStruc, confgData);  continue;  end
            
            inStruc.h5name = [confgData.outDir fileName];
            
            generateh5Cube(inStruc, confgData);
            
            inStruc.zoneHrDiff = timezone(inStruc.thisLon);
            % Adjust input time / date: Assume that the sample is taken at 11pm
            % FWC say their data is collected in daylight hours (mostly)
            inStruc.endTimeUTC = 23+inStruc.zoneHrDiff;
            
            if inStruc.endTimeUTC > 24; inStruc.endTimeUTC = inStruc.endTimeUTC-24; inStruc.dayEnd=inStruc.dayEnd+1; end
            inStruc.dayEndFraction = inStruc.dayEnd+inStruc.endTimeUTC/24;
            inStruc.dayStart = inStruc.dayEnd - confgData.numberOfDaysInPast;
            inStruc.dayStartFraction = inStruc.dayEndFraction - confgData.numberOfDaysInPast;
            inStruc.dayStartS = datestr(inStruc.dayStart,29);
            inStruc.dayEndS = datestr(inStruc.dayEnd,29);
            inStruc.UTCTime = sprintf('T%02d:00:00Z', inStruc.endTimeUTC);

            
            if exist(inStruc.h5name, 'file')==2;  delete(inStruc.h5name);  end
            
            %Put images, count, dates and deltadates into output .H5 file
            addDataH5(inStruc, confgData);
            getModData(inStruc, confgData);
            
            % Zip up the data and delete the original
            gzip(inStruc.h5name);
            system([rmcommand confgData.outDir '*.h5']);
            outputIndex = outputIndex+1;
        catch e   
            str_iden = num2str(ii);
            logErr(e,str_iden) 
            continue      
        end
    end
end

function addDataH5(inStruc, confgData)
%% addDataH5 creates a H5 file and stores ground truth data to it 
    %  Adds extracted information to one H5 file per datapoint in ground truth
    %
    % USAGE:
    %   addDataH5(inStruc, confgData)
    % INPUT:
    %   inStruc - Contains all the input parameters for the function
    %   confgData - Configuration information extracted from XML
    % OUTPUT:
    %   - 
    
    fid = H5F.create(inStruc.h5name);
    plist = 'H5P_DEFAULT';
    gid = H5G.create(fid,'GroundTruth',plist,plist,plist);
    H5G.close(gid);
    H5F.close(fid);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'MatlabGroundTruthFile', confgData.inputFilename);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'lineInGrouthTruthMatlab', inStruc.ii);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'thisLat', inStruc.thisLat);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'thisLon', inStruc.thisLon);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'thisCount', inStruc.thisCount);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'dayEnd', inStruc.dayEnd);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'dayStart', inStruc.dayStart);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'dayEndFraction', inStruc.dayEndFraction);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'dayStartFraction', inStruc.dayStartFraction);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'resolution', confgData.resolution);
    h5writeatt(inStruc.h5name,'/GroundTruth', 'distance1', confgData.distance1);
    numberOfMods = length(confgData.mods);

    %% Loop through all the modulations
    theseMods = cell(numberOfMods,1);
    for modIndex = 1:numberOfMods
        theseMods{modIndex} = confgData.mods{modIndex}.Text;
    end
    hdf5write(inStruc.h5name,'/Modnames',theseMods, 'WriteMode','append');
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
    index = inStruc.ii;
    downloadDir = confgData.downloadDir;
    wgetStringBase = confgData.wgetStringBase;
    distance1 = confgData.distance1;
    disp(['Fetching data for ',inStruc.h5name]);
    
    zone = utmzone(thisLat, thisLon);
    utmstruct = defaultm('utm');
    utmstruct.zone = zone;
    utmstruct.geoid = wgs84Ellipsoid; %almanac('earth','grs80','meters');
    utmstruct = defaultm(utmstruct);

    %% Loop through all the modulations
    for modIndex = 1:numberOfMods
        thisMod = confgData.mods{modIndex}.Text;
        subMods = strsplit(thisMod,'-');
        h5writeatt(inStruc.h5name,'/GroundTruth', 'Projection', ['utm wgs84Ellipsoid ' zone] );

        if strcmp(subMods{1},'gebco')
            [elevationIm, elevationPoints, elevationPointsProj] = getGEBCOData(confgData, thisLat, thisLon, utmstruct);
            addToH5(inStruc.h5name, thisMod, elevationIm, 0, 0, elevationPoints, elevationPointsProj);
            continue;
        end
        % product suites are either oc, iop or sst
        % sensors are either modisa,modist,viirsn,goci,meris,czcs,octs or 'seawifs'
        % sst: sstref, sst4, sst 1Km resolution for all sst
        % Search for "granules" at a particular lat, long and date range (output goes in Output.txt)
        
        pyOpt = [' --data_type=' subMods{1} ' --sat=' subMods{2} ' --slat=' num2str(thisLat) ...
                 ' --slon=' num2str(thisLon) ' --stime=' dayStartS UTCTime ' --etime=' dayEndS UTCTime];
        disp(['Searching granules for: --mod=',subMods{3}, pyOpt])
        exeName = [pythonStr ' fd_matchup.py', pyOpt,' > cmdOut.txt'];
        system(exeName);

        %% Loop through .nc files, veryify and download / extract
        
        fid = fopen('Output.txt');   
        tline = fgetl(fid);
        indInput = 1;  clear thisInput; clear thisList;
        while ischar(tline)
            [~,nc_name,~] = fileparts(tline);
            if nc_name(end) ~= '4'   %ignore SST4
                thisDate=julian2time(nc_name(2:14));
                thisInput(indInput).line = tline;
                thisInput(indInput).date = thisDate;
                thisInput(indInput).deltadate = inStruc.dayEndFraction-thisDate;
                indInput = indInput + 1;
            end
            tline = fgetl(fid);
        end
        fclose(fid);
        disp(['Found ', num2str(length(thisInput)), ' granules.' ])
        
        %% Re-order the list of found data
        thisList = zeros(length(thisInput),1);
        for iii = 1: length(thisInput); thisList(iii) = thisInput(iii).deltadate; end
        [~, sortIndex] = sort(thisList);
        listLength = length(sortIndex);
        
        if strcmp(subMods{1},'sst') 
            sortIndex = sortIndex(1); 
            listLength = 1;
        end % Needed to prevent issues with SST4
        
        %% Loop through previous times and extract images and points from .nc files
        % iyyyydddhhmmss.L2_rrr_ppp,
        % where i is the instrument identifier  yyyydddhhmmss
        clear theseDates theseDeltaDates theseImages;
        thesePointsOutput = []; thesePointsProjOutput = [];
        theseImages = cell(listLength,1);theseDates = cell(listLength,1);theseDeltaDates = cell(length(sortIndex),1);
        thesePointsNew = cell(listLength,1);
        thesePointsProjNew = cell(listLength,1);
        
        %Download all granules found
        %Uses the parallel computing toolbox, if not available change to a
        %normal for loop.
        tic
        cluster = parcluster('local'); nworkers = cluster.NumWorkers;
        parfor (iii = 1:listLength,nworkers)
            thisIndex = sortIndex(iii);
            thisLine = thisInput(thisIndex).line;
            thisDate = thisInput(thisIndex).date;
            thisDeltaDate = thisInput(thisIndex).deltadate;
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
            
            try %Some nc files cannot be read, so we catch those cases
                theseDates{iii} = thisDate;
                theseDeltaDates{iii} = thisDeltaDate;
                [theseImages{iii}, thesePoints, thesePointsProj] = getData(fileName,  thisLat, thisLon, distance1, confgData.resolution, ['/geophysical_data/' subMods{3}], utmstruct);
                thesePointsNew{iii} = [thesePoints ones(size(thesePoints,1),1)*theseDeltaDates{iii}];
                thesePointsProjNew{iii} = [thesePointsProj ones(size(thesePointsProj,1),1)*theseDeltaDates{iii}];     
            catch e2
                logErr(e2,['index: ',num2str(index),' mod: ',num2str(modIndex), ' granule: ',num2str(iii)]); 
            end 
        end
       
        %Get rid of any empty cells
            theseDates = theseDates(~cellfun('isempty', theseImages));
            theseDeltaDates = theseDeltaDates(~cellfun('isempty', theseImages));
            theseImages = theseImages(~cellfun('isempty', theseImages));
        %Build output arrays
        for iii = 1:listLength
            thesePointsOutput = [thesePointsOutput; thesePointsNew{iii}];
            thesePointsProjOutput = [thesePointsProjOutput; thesePointsProjNew{iii}];
        end
        disp(['Time taken to process granules: ', num2str(toc)]);
        
        addToH5(inStruc.h5name, thisMod, theseImages, theseDates, theseDeltaDates, thesePointsOutput, thesePointsProjOutput);
        %h5disp(inStruc.h5name);
    end
end

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
end

function addToH5(h5name, thisMod, theseImages, theseDates, theseDeltaDates, thesePointsOutput, thesePointsOutputProj)
    %% add Ims, theseDates, theseDeltaDates and Points to output H5 file
    %
    % USAGE:
    %   addToH5(h5name, thisMod, theseImages, theseDates, theseDeltaDates, thesePointsOutput)
    % INPUT:
    %   h5name - name of H5 name to be output
    %   thisMod = Name of the output modality
    %   theseImages - Cell array of output binned images (for this modality)
    %   theseDates - The actual capture dates of the points and images output
    %   theseDeltaDates - The delta dates (difference from capture date) of the points and images output
    %   thesePointsOutput - 4D Array of points output
    %   thesePointsOutputProj - 4D Array of projected points output
    % OUTPUT:
    %   - 
    hdf5write(h5name,['/' thisMod  '/Ims'],theseImages, 'WriteMode','append');
    hdf5write(h5name,['/' thisMod  '/theseDates'],theseDates, 'WriteMode','append');
    hdf5write(h5name,['/' thisMod  '/theseDeltaDates'],theseDeltaDates, 'WriteMode','append');
    hdf5write(h5name,['/' thisMod  '/Points'],thesePointsOutput, 'WriteMode','append');
    hdf5write(h5name,['/' thisMod  '/PointsProj'],thesePointsOutputProj, 'WriteMode','append');
end

function logErr(e,str_iden)
    fileID = fopen('errors.txt','at');
    identifier = ['Error procesing sample ',str_iden, ' time: ', datestr(now)];
    text = [e.identifier, '::', getReport(e)];
    fprintf(fileID,'%s\n\r ',identifier);
    fprintf(fileID,'%s\n\r ',text);
    fclose(fileID);
end
