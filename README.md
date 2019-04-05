# HAB Datacube Extraction

This project is separated into training and testing tasks

The training task takes a groundtruth MATLAB .mat file containing all of 
the lat, long, date and (HAB) count information of a HAB.  This then 
generates an H5 file per sample line in the ground truth file.  
This H5 file contains all of the imaging data from the satelites.  
Thse H5 files can then be used for machine learning (cross validation etc.).

The testing task separates a geographical region into a test grid.  
Datacubes are then generated for each position within the test grid.

## Files
* **train_genAllH5s.m**: Input the xml config file, then load the .mat ground truth
file.  Then calls genSingleH5s to form all H5 datacubes.
* **test_genAllH5s.m**: Defines a grid of locations to test.  Then calls
genSingleH5s to form all H5 datacubes.
* **genSingleH5s.m**: Function that inputs inStruc and confgData to generate
single H5 datacube.  Searches for all relevant .nc granules (using 
fd_matchup.py and NASA's  CMR interface).  Datacubes are formed from all 
the local .nc granules
* **getData.m**: Get the actual datacubes from a .nc file (called from getDataOuter)
* **fd_matchup.py**: Modified Seadas code to access CMR NASA interface
* **configHAB.xml**: Configuration file input by test/train_genAllH5s
* **configHABmac.xml**: Configuration file input by test/train_genAllH5s (on a mac)

The datacubes are generated for each of the lines in the groundtruth file.  Each datacube is named as follows:

* Cube_outputIndex_inputIndex_sampleDate.h5.gz

Where outputIndex is the numerical number of the hdf5 file and inputIndex is the line number in the groundtruth file.  These two numbers can differ due to network failures in the ingress of the data (using the code below).  SampleDate is the date in the respective line of the groundtruth file.

A data cube is extracted for each positive and negative HAB event. It has not been tested on windows.  A MATLAB .mat file containing the ground truth extracted from the excel files have been created (using ingressFloridaHABs.m).  Two different .mat files have been created (from 2003 to 2018).  This temporal span has been created so that both MODISA and MODIST are able to cover all data.  The two .mat files are

* florida_2003-2018-50K.mat
* florida_2003-2018-5K.mat

The first one labels any count above 50,000 (as indicated in the paper [5]) to be a positive event.  Negative events are from a random selection of data points where count is 0 (matching the approx. number of positive events). 
The second one labels any count above 5,000 (as indicated in an email from the FWC) to be a positive event.  Negative events are from a random selection of data points where count is 0 (matching the approx. number of positive events).  All of the current code has used the florida_2003-2018-50K.mat file and associated data.

## Datacube Extaction

Data cube extraction is achieved using the MATLAB file:

* train_genAllH5s.m

This file loops through all of the data points (in the chosen ground truth data).  For each loop, the modalities are also looped through.  For each modality, NASA’s CMR search is used (see below) to search for the relevant netCDF granule files.  This CMR search uses a python script fd_matchup.py.  This python script takes a latitude, longitude, date (and time) and temporal window.  The output is a text file called Output.txt with a list of netCDF web addresses.  Each of these granules are downloaded using wget.  

* test_genAllH5s.m

Defines a grid of locations to test.  Then calls genSingleH5s to form all H5 datacubes.

For each of the netCDF files a sub-datacube is extracted using the MATLAB function file:

* getData.m

This file reprojects the data points in the netCDF to a local UTM projection.  UTM reprojection is necessary in order to overcome level 2 capture artefacts such as the bow-tie effect. 

* http://www.sat.dundee.ac.uk/modis-bowtie.html

The result of the reprojection is then binned and the output is output into the output HDF5 file as Ims together with the original data.

It should be noted that there is currently a potential issue with obtaining data at the edges of granules.

## HDF5 File Output
The HDF5 file output represents each datacube.  The global metadata of each cube is contained within the GroundTruth group:
 
```
GroundTruth/MatlabGroundTruthFile: Name of the ground truth file
GroundTruth/lineInGrouthTruthMatlab: Line number in the ground truth file
GroundTruth/thisLat: Latitude in the ground truth file
GroundTruth/thisLon: Longitude in the ground truth file
GroundTruth/thisCount:  Algae count
GroundTruth/dayEnd: Date in the ground truth file
GroundTruth/dayStart:  Date - numberOfDaysInPast
GroundTruth/dayEndFraction: Take into account the time of capture and time zone
GroundTruth/dayStartFraction: 
GroundTruth/resolution:  Resolution of the output images (in metres)
GroundTruth/distance1:   Spatial width of datacube (in metres)
GroundTruth/projection:  Type of projection of the output images
```

A group is created for each modality (including GEBCO).  Binned images are then entered into a group together with the real-valued (Lat, Lon, Val) outputs from the UTM reprojection (points).

Each Modality has a group in the datacube HDF5 file.  These groups contain the following datasets.

```
Ims: The binned re-projected UTM images for each modality
Points: the original points (lat, lon, date)
PointsProj: the re-projected UTM values
Thesedates: the actual dates of the netCDF files 
Thesedeltadates: the delta dates of Thesedates (relative to the capture date)
```

### Configuration
The configuration of the datacube extraction is contained within an xml file (configHAB.xml). A typical version of this file is 
 
```
<?xml version="1.0" encoding="utf-8"?>
<confgData>
   <inputFilename>/home/cosc/csprh/linux/HABCODE/code/HAB/extractData/work/florida_2003-2018-50K</inputFilename>
   <gebcoFilename>/space/csprh/HAB/GEBCO/GEBCO.nc</gebcoFilename>
   <downloadFolder>/home/cosc/csprh/linux/HABCODE/scratch/downloads/</downloadFolder>
   <wgetStringBase>/usr/bin/wget</wgetStringBase>
   <trainDir>/home/cosc/csprh/linux/HABCODE/scratch/HAB/florida/train/</trainDir>
   <trainImsDir>/home/cosc/csprh/linux/HABCODE/scratch/HAB/CNNIms/florida/train</trainImsDir>
   <testDir>/home/cosc/csprh/linux/HABCODE/scratch/HAB/florida/test/</testDir>
   <testImsDir>/home/cosc/csprh/linux/HABCODE/scratch/HAB/CNNIms/florida/test</testImsDir>
   <testDate>737173</testDate>
   <resolution>2000</resolution>
   <distance1>100000</distance1>
   <numberOfDaysInPast>10</numberOfDaysInPast>
   <numberOfSamples>-1</numberOfSamples>
   <Modality>gebco</Modality>
   <Modality>oc-modisa-chlor_a</Modality>
   <Modality>oc-modisa-Rrs_412</Modality>
   <Modality>oc-modisa-Rrs_443</Modality>
   <Modality>oc-modisa-Rrs_488</Modality>
   <Modality>oc-modisa-Rrs_531</Modality>
   <Modality>oc-modisa-Rrs_555</Modality>
   <Modality>oc-modisa-par</Modality>
   <Modality>sst-modisa-sstref</Modality>
   <Modality>oc-modist-chlor_a</Modality>
   <outputRes>1000</outputRes>
   <alphaSize>2</alphaSize>
   <threshCentrePoint>0.5</threshCentrePoint>
   <threshAll>0.2</threshAll>
   <preLoadMinMax>1</preLoadMinMax>
</confgData>
```

The XML elements are:

```
inputFilename: name of MATLAB ground truth file
gebcoFilename: name of the netCDF bathymetry GEBCO information.  GEBCO is from https://www.gebco.net/
downloadFolder: intdroduced so the granules are downloaded to a temporay folder
wgetStringBase: the wget string (differs for Linux/OSX etc.)
trainDir: place to store the output training HDF5 files
trainImsDir: directory to store quantised training images
testDir: place to store the output testing HDF5 files
testImsDir: directory to store quantised test images
testDate: The date to output the test data
Resolution: The resolution of the bins (for reprojection) for the generation of images (in meters).  Currently, 2Km (2000m).  Most of the MODIS data is 1Km, but on reprojection binning at 1Km would result in images that are too sparse.
Distance1: The distance between the central location of the sample to the upper, lower, east and west edges (in metres).
numberOfDaysInPast: Temporal window
numberOfSamples: Number of samples to use (in training).  if -1 then use all
Modalities: A list of the modalities to extract (GEBCO is a special case as it extracts the Bathymetry information surrounding the sample location).
outputRes: resolution output
alphaSize: size of alphashape (used to quanisation of output)
threshCentrePoint: Threshold of centre area near detection to decided whether to
discount datacube
threshAll: Threshold of amount of data in whole image of data cube to deside on
whether to discount datacube
preLoadMinMax: set to 1 to reload precomputed max and min values for output
datacube images. Set to anything else for recalculation
```

##	Granule Search

The CMR search mechanism has been adopted to obtain the correct granule according to the latitude, longitude and date triplet.

* https://cmr.earthdata.nasa.gov/search/

### Date Issues
It has been assumed that the capture time of the measurements was during daylight hours.  The capture time was therefore assumed to be 11pm + the zonal time difference (as the CMR system uses GMT time references).

## Data-Cube Conversion to Machine Learning Image Ingress Format

The datacubes are converted to a series of images in a directory structure described below using the MATLAB functions train_cubeSequence.m and test_cubeSequence.m
train_cubeSequence.m and test_cubeSequence.m differ in as much as test_cubeSequence.m does no checking.  They both call outputImagesFromDataCube.m


An example output directory structure is as follows

* /1/101/3/1.png
* /1/101/3/2.png
* /1/101/3/3.png
* /1/101/3/4.png
* /1/101/3/5.png
* /1/101/3/6.png
* /1/101/3/7.png
* /1/101/3/8.png
* /1/101/3/9.png
* /1/101/3/10.png

The numbered name of the jpg image is the quantised day of capture (from the day of capture in the ground truth file) i.e. they are the five days quantised. 

Split output into HAB Class (0/1), Ground truth line number, Modality (1-10)

This is achieved using the MATLAB script (with no input parameters)

* postprocess/test_cubeSequence.m
* postprocess/train_cubeSequence.m

## Generation of Bi-monthly Chlor_a Values

All of the florida bi-monthly average values are downloaded using the following
code
* test/downloadAll8DModisAChlr.m

