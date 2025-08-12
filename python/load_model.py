from resemblyzer import VoiceEncoder

# 1. 创建模型对象，会自动下载预训练权重到本地缓存
encoder = VoiceEncoder()

# 2. 获取模型的 state_dict
state_dict = encoder.state_dict()

# 3. 保存为 .pth 文件
import torch
torch.save(state_dict, "resemblyzer_voice_encoder.pth")

print("模型权重已保存到 resemblyzer_voice_encoder.pth")
