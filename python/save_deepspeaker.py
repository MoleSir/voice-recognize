import librosa
import numpy as np
import tensorflow as tf

from deep_speaker.constants import SAMPLE_RATE
from deep_speaker.conv_models import DeepSpeakerModel
from deep_speaker.test import batch_cosine_similarity

# Define the model here.
model = DeepSpeakerModel(pcm_input=True)

# Load the checkpoint.
model.m.load_weights('ResCNN_triplet_training_checkpoint_265.h5', by_name=True)

model.m.save('saved_model/deep_speaker')

converter = tf.lite.TFLiteConverter.from_saved_model('saved_model/deep_speaker')
# 选择优化选项，比如浮点16或动态量化
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open('deep_speaker.tflite', 'wb') as f:
    f.write(tflite_model)