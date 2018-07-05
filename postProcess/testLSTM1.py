import numpy as np
import h5py
import os
import tensorflow as tf
import tensorflow 
from tensorflow.python import keras
from tensorflow.python.keras.preprocessing import sequence
from tensorflow.python.keras.models import Sequential
from tensorflow.python.keras.layers import Dense, Embedding
from tensorflow.python.keras.layers import LSTM

hf = h5py.File('/Users/csprh/Dlaptop/MATLAB/MYCODE/HAB/WORK/HAB/florida1/LSTMData/LSTMFlor1.h5', 'r');

dataX = hf.get('XLSTMData')
dataY = hf.get('YLSTMData')
dataX = np.array(dataX)
dataY = np.array(dataY)

#np.shape(dataX)
dataX2 = dataX[:,0:1000,:]
np.shape(dataX2)

print(dataY)

print("Shape of training set: {}".format(dataX.shape))


print('Build model...')
model = Sequential()
model.add(LSTM(128, dropout=0.2, recurrent_dropout=0.2, input_shape=(None, 3)))
model.add(Dense(2, activation='sigmoid'))

# try using different optimizers and different optimizer configs
model.compile(loss='binary_crossentropy',
              optimizer='adam',
              metrics=['accuracy'])

print('Train...')
one_hot_labels = keras.utils.to_categorical(dataY, num_classes=2)
#print(one_hot_labels[:,0])
model.fit(dataX2,one_hot_labels,epochs=200)
#pred = model.predict(dataX)
#predict_classes = np.argmax(pred,axis=1)
#print("Predicted classes: {}",predict_classes)
#print("Expected classes: {}",predict_classes)