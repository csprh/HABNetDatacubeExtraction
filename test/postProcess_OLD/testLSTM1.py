import numpy as np
import scipy.io
import os
import tensorflow as tf
import tensorflow
import h5py
from tensorflow.python import keras
from tensorflow.python.keras.preprocessing import sequence
from tensorflow.python.keras.models import Sequential
from tensorflow.python.keras.layers import Dense, Embedding
from tensorflow.python.keras.layers import Conv1D
from tensorflow.python.keras.layers import MaxPooling1D
from tensorflow.python.keras.layers import LSTM
from tensorflow.python.keras.layers import TimeDistributed
from tensorflow.python.keras.layers import Bidirectional
from tensorflow.python.keras.layers import Dropout
import platform

if platform.system() == "Darwin":
   hf = h5py.File('/Users/csprh/Dlaptop/MATLAB/MYCODE/HAB/WORK/HAB/florida1/LSTMData/LSTMFlor1.h5', 'r')
else:
   hf = h5py.File('/mnt/storage/home/csprh/scratch/HAB/florida1/LSTMData/LSTMFlor2.h5','r')


dataX = hf.get('XLSTMData')
dataY = hf.get('YLSTMData')
dataX = np.array(dataX)
dataY = np.array(dataY)

#np.shape(dataX)
dataX2 = dataX[:,0:500,:]
dShape = np.shape(dataX2)
dims = dShape[2]
n_timesteps = dShape[1]

print(dataY)

print("Shape of training set: {}".format(dataX.shape))


print('Build model...')
model = Sequential()
#model.add(Bidirectional(LSTM(20, return_sequences=True),
#	input_shape=(n_timesteps, 1)))
#model.add(Conv1D(128,3,input_shape=(501,3), activation='relu'))
model.add(Conv1D(input_shape=(n_timesteps,dims), filters=64, kernel_size=5,padding='valid', activation='relu', strides=1))
model.add(MaxPooling1D(pool_size=2))
model.add(Dropout(0.25))
#model.add(LSTM(128,dropout=0.2, recurrent_dropout=0.2, return_sequence=True))
model.add(LSTM(128, dropout=0.2, recurrent_dropout=0.2,return_sequences=True,input_shape=(None,3)))
model.add(LSTM(128,dropout=0.5,recurrent_dropout=0.5))
model.add(Dense(1, activation='sigmoid'))
model.compile(loss='binary_crossentropy',
              optimizer='adam',
              metrics=['accuracy'])

print('Train...')
one_hot_labels = keras.utils.to_categorical(dataY, num_classes=2)
#print(one_hot_labels[:,0])
model.fit(dataX2,dataY, validation_split=0.2, epochs=200)
#model.fit(dataX2,one_hot_labels,validation_split=0.2,epochs=200)
#pred = model.predict(dataX)
#predict_classes = np.argmax(pred,axis=1)
#print("Predicted classes: {}",predict_classes)
#print("Expected classes: {}",predict_classes)
