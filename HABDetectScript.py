#!/usr/bin/python
# This Code takes a datacube and outputs quantised images for all days and
# modalities in the outputDirectory.
# This script generates a number of png files from the datacube over the
# number of days in the datacube.  The bottleneck features are extracted
# from each png file using extract_features.py
# Once the numpy file is extracted from each modality, testHAB.py is used
# to generate a classification.  testHAB.py injests numpy file generated
# by extract_features.py, loads a model and generates a classfication
# probability
#
# THE UNIVERSITY OF BRISTOL: HAB PROJECT
# Author Dr Paul Hill March 2019

import sys
import os
#import matlab.engine
import pudb; pu.db

#eng = matlab.engine.start_matlab()



h5name = '/home/cosc/csprh/linux/HABCODE/scratch/HAB/tmpTest/testCubes/Cube_09073_09081_737173.h5'
outputDirectory = '/home/cosc/csprh/linux/HABCODE/scratch/HAB/tmpTest/CNNIms'
os.chdir(r'../modelHAB')
#eng.HABDetect(h5name, outputDirectory)
mstring = 'matlab /nosplash /nodesktop /r HABDetect('
os.system( mstring + '\'' + h5name + '\',\'' + outputDirectory + '\')')
extract_features('cnfgXMLs/NASNet11_lstm0.xml', outputDirectory)
testHAB('cnfgXMLs/NASNet11_lstm0.xml', outputDirectory)



