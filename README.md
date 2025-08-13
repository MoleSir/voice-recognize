# voice

A voice recg application


## 问题 
 
- 模型导出（.pth -> onxx -> tf -> tflite），使用 Resemblyzer 难以导出，并且推理报错
- 最后采用的模型是 deep-speaker，本身就是用 tf 写的，所以导出的时候很方便，并且这个模型直接把 Mel 的过程也实现了。只需要输入 PCM
- 麦克风使用的是 flutter_sound 库


## References

- https://github.com/resemble-ai/Resemblyzer
- https://blog.csdn.net/gitblog_01295/article/details/143045366
- https://github.com/anarchuser/mic_stream/blob/main/example/lib/main.dart
- https://yf-cheng.com/zh-cn/p/tts-evaluation-targets/
- https://github.com/philipperemy/deep-speaker