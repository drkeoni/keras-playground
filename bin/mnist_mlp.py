#!/usr/bin/env python3
'''Trains a simple deep NN on the MNIST dataset.
Gets to 98.40% test accuracy after 20 EPOCHS
(there is *a lot* of margin for parameter tuning).
2 seconds per epoch on a K520 GPU.
'''
#
# This example of using Keras comes from https://github.com/keras-team/keras/blob/master/examples/mnist_mlp.py
#
from __future__ import print_function

import os
import json

import keras
from keras.datasets import mnist
from keras.models import Sequential
from keras.layers import Dense, Dropout, GaussianNoise
from keras.optimizers import RMSprop, Nadam

batch_size = 128
num_classes = 10
EPOCHS = 5

ncols = 28
nrows = 28
num_pixels = ncols * nrows

# the data, split between train and test sets
(x_train, y_train), (x_test, y_test) = mnist.load_data()

x_train = x_train.reshape(60000, num_pixels)
x_test = x_test.reshape(10000, num_pixels)
x_train = x_train.astype('float32')
x_test = x_test.astype('float32')
x_train /= 255
x_test /= 255
print(x_train.shape[0], 'train samples')
print(x_test.shape[0], 'test samples')

# convert class vectors to binary class matrices
y_train = keras.utils.to_categorical(y_train, num_classes)
y_test = keras.utils.to_categorical(y_test, num_classes)

model = Sequential()
model.add(Dense(512, activation='relu', input_shape=(num_pixels,)))
model.add(GaussianNoise(0.1))
model.add(Dropout(0.2))
model.add(Dense(512, activation='relu'))
model.add(Dropout(0.2))
model.add(Dense(num_classes, activation='softmax'))

model.summary()

model.compile(loss='categorical_crossentropy',
              optimizer=RMSprop(),
#              optimizer=Nadam(),
              metrics=['accuracy'])

history = model.fit(x_train, y_train,
                    batch_size=batch_size,
                    epochs=EPOCHS,
                    verbose=1,
                    validation_data=(x_test, y_test))
score = model.evaluate(x_test, y_test, verbose=0)
print('Test loss:', score[0])
print('Test accuracy:', score[1])

with open('mnist_mlp.json','w') as outfile:
    data = json.loads(model.to_json())
    outfile.write(json.dumps(data, indent=4, sort_keys=True) + os.linesep)
