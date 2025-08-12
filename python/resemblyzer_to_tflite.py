import torch
from resemblyzer import VoiceEncoder
import onnx
import onnxruntime as ort
import subprocess
import numpy as np

# 1. 加载 VoiceEncoder
encoder = VoiceEncoder()

# 2. 创建一个假输入 (batch=1, mel_frames=50, mel_bins=40)
#   VoiceEncoder 接收的输入是 (frames, mel_bins) 或 (batch, frames, mel_bins)
dummy_input = torch.rand(1, 50, 40, dtype=torch.float32)

# 3. 导出为 ONNX
onnx_path = "voice_encoder.onnx"
torch.onnx.export(
    encoder,                                # 模型
    dummy_input,                            # 假输入
    onnx_path,                              # 输出文件
    input_names=["mel_input"],
    output_names=["embedding"],
    dynamic_axes={
        "mel_input": {0: "batch_size", 1: "n_frames"},  # batch 和帧数都动态
        "embedding": {0: "batch_size"},
    },
    opset_version=11,
)

print(f"ONNX 模型已保存到 {onnx_path}")

# 4. 检查 ONNX 是否正常
onnx_model = onnx.load(onnx_path)
onnx.checker.check_model(onnx_model)
print("ONNX 模型验证通过")

# 5. 使用 onnxruntime 测试
ort_sess = ort.InferenceSession(onnx_path)
out = ort_sess.run(None, {"mel_input": np.random.rand(1, 50, 40).astype(np.float32)})
print("ONNX 推理输出维度：", out[0].shape)

# 6. 转换为 TFLite (需要安装 onnx-tf 与 TensorFlow)
#    先转为 TensorFlow SavedModel
subprocess.run([
    "onnx-tf", "convert", "-i", onnx_path, "-o", "voice_encoder_tf"
])

# 7. 用 TensorFlow 转 TFLite
import tensorflow as tf
converter = tf.lite.TFLiteConverter.from_saved_model("voice_encoder_tf")

# 允许使用 Select TF Ops（支持更多 TF 原生算子）
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,    # 普通 TFLite ops
    tf.lite.OpsSet.SELECT_TF_OPS       # 允许 TF ops
]

# 关闭 experimental 版本的 tensor list ops 降级，避免报错
converter._experimental_lower_tensor_list_ops = False

tflite_model = converter.convert()

with open("voice_encoder.tflite", "wb") as f:
    f.write(tflite_model)

print("TFLite 模型已保存")
