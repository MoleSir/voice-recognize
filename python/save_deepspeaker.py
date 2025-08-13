
import tensorflow as tf
from deep_speaker.conv_models import DeepSpeakerModel
from deep_speaker.constants import SAMPLE_RATE

FIXED_LEN = 2 * SAMPLE_RATE  # 2 秒

# 1. 定义模型
model = DeepSpeakerModel(pcm_input=True)
model.m.load_weights('ResCNN_triplet_training_checkpoint_265.h5', by_name=True)

# 2. 固定输入长度，生成 concrete function
full_model = tf.function(
    lambda x: model.m(x),
    input_signature=[tf.TensorSpec(shape=[1, FIXED_LEN], dtype=tf.float32)]
)
concrete_func = full_model.get_concrete_function()

# 3. 转换 TFLite
converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open("deep_speaker_2s.tflite", "wb") as f:
    f.write(tflite_model)
