# HAB GroundTruth Extraction

This project takes a MATLAB .mat file containing all of the lat, long, date
and count information of a HAB.  This then generates an H5 file per sample 
line in the ground truth file.  This H5 file contains all of the imaging 
data from the satelites.  Thse H5 files can then be used for machine 
learning (cross validation etc.).

## Files
**getDataOuter**: Input the xml config file, then load the .mat ground truth
file.  Loop through each line in the file, search for .nc files via CMR
NASA interface (using fd_matchup.py).  Loop through all of the .nc files, 
download using wget and and call getData on each.  Delete downloaded .nc file.
**getData**: Get the actual datacubes from a .nc file (called from getDataOuter)
**fd_matchup.py**: Modified Seadas code to access CMR NASA interface
