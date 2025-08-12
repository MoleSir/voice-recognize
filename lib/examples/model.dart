import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TestModelWidget extends StatelessWidget {
  const TestModelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed:() async {
          await testVoiceEncoder();
        }, 
        child: Text("Start Test")
      ),
    );
  }
}

Future<void> testVoiceEncoder() async {
  final interpreter = await Interpreter.fromAsset('assets/model/deep_speaker.tflite');
  print('模型加载成功');

  final int numSamples = 48000; // 假设模型输入长度是48000采样点
  // 用随机数模拟PCM数据，范围 -1.0 ~ 1.0
  final random = Random(123);
  final pcmData = List<double>.generate(numSamples, (_) => random.nextDouble() * 2 - 1);

  final input = [pcmData]; // shape: [1, 48000]
  final output = List.filled(512, 0.0).reshape([1, 512]);

  interpreter.run(input, output);

  print('推理完成，声纹向量（512维）：');
  print(output[0]);
}
