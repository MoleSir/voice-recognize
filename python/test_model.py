from resemblyzer import VoiceEncoder, preprocess_wav
from pathlib import Path
import numpy as np

# 1. 加载模型
encoder = VoiceEncoder()

# 2. 读取音频文件，转换为 waveform（numpy array，采样率16kHz）
wav_fpath_1 = Path("./assets/music/花海.wav")
wav_fpath_2 = Path("./assets/music/轨迹.wav")

wav1 = preprocess_wav(wav_fpath_1)
wav2 = preprocess_wav(wav_fpath_2)

# 3. 提取声纹embedding（默认是512维）
embed1 = encoder.embed_utterance(wav1)
embed2 = encoder.embed_utterance(wav2)

# 4. 计算余弦相似度
cos_sim = np.dot(embed1, embed2) / (np.linalg.norm(embed1) * np.linalg.norm(embed2))

print(f"两个音频的余弦相似度: {cos_sim:.4f}")

if cos_sim > 0.75:
    print("可能是同一个人")
else:
    print("可能不是同一个人")
