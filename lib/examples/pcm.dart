import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class RecorderDemo extends StatefulWidget {
  const RecorderDemo({super.key});
  @override
  State<RecorderDemo> createState() => _RecorderDemoState();
}

class _RecorderDemoState extends State<RecorderDemo> {
  // _recorderInitialized 和 _modelLoaded 用来通知 UI 
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderInitialized = false;

  final List<double> _pcmData = [];
  StreamSubscription? _audioStreamSubscription;

  late Interpreter _interpreter;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadModel();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    _recorderInitialized = true;
    setState(() {});
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model/deep_speaker.tflite');
    setState(() {
      _modelLoaded = true;
    });
  }

  void _processPCMData(Uint8List data) {
    final byteData = ByteData.sublistView(data);
    for (int i = 0; i < data.length; i += 2) {
      final sample = byteData.getInt16(i, Endian.little);
      _pcmData.add(sample / 32768.0);
    }
  }

  Future<void> _startRecording() async {
    if (!_recorderInitialized) return;

    _pcmData.clear();

    /*
      StreamController 是 Dart 中管理数据流的核心工具。
      这里的作用是“承接”从录音器发出的原始 PCM 数据流。它本身提供了两部分：
        - 一个输入端（Sink）用于接收数据，
        - 一个输出端（Stream）允许其他地方订阅监听数据。
    */
    final audioStreamController = StreamController<Uint8List>();

    // 注册函数，当 audioStreamController 得到一个 Uint8List 就执行 _processPCMData(pcmBytes);
    /*
      audioStreamController.stream 是一个 Stream<Uint8List>，你可以理解为“音频数据通道”。
      .listen() 表示“订阅”这个数据流，每当流里来了新数据，就会调用传入的回调函数。

      这里的回调函数：
        - 参数 pcmBytes 是一段新的 PCM 原始字节数据，
        - 调用 _processPCMData(pcmBytes) 把字节转换成 float 并存入 _pcmData。
    */
    _audioStreamSubscription = audioStreamController.stream.listen((pcmBytes) {
      _processPCMData(pcmBytes);
    });


    /*
      录音器采集到的 PCM 数据就会源源不断地写入这个 sink
      接受到一个 Uint8List，就调用 _processPCMData 将数据插入 _pcmData
    */
    await _recorder.startRecorder(
      // 将 _recorder 数据发送到 audioStreamController
      toStream: audioStreamController.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() {});
  }

  Future<void> _stopRecording() async {
    if (!_recorderInitialized) return;

    await _recorder.stopRecorder();
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    print('录音结束，PCM长度：${_pcmData.length}');

    if (_modelLoaded) {
      _runModelInference();
    } else {
      print('模型未加载完成');
    }

    setState(() {});
  }

  void _runModelInference() {
    // 假设模型输入是 [1, input_length] 的 float32 tensor
    // 你需要根据模型输入长度裁剪或填充_pcmData，这里假设模型输入长度是16000(1秒采样)
    const int inputLength = 16000;

    List<double> inputData;
    if (_pcmData.length > inputLength) {
      inputData = _pcmData.sublist(0, inputLength);
    } else if (_pcmData.length < inputLength) {
      inputData = List<double>.from(_pcmData);
      inputData.addAll(List.filled(inputLength - _pcmData.length, 0.0));
    } else {
      inputData = _pcmData;
    }

    // 模型输入batch
    var input = [inputData];

    // 模型输出缓冲，假设是512维embedding
    var output = List.filled(512, 0.0).reshape([1, 512]);

    _interpreter.run(input, output);

    print('模型推理结果 embedding: ${output[0]}');
  }

  @override
  void dispose() {
    _audioStreamSubscription?.cancel();
    _recorder.closeRecorder();
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _recorder.isRecording;
    return Scaffold(
      appBar: AppBar(title: const Text('PCM录音 + 模型推理 Demo')),
      body: Center(
        child: GestureDetector(
          onTapDown: (_) => _startRecording(),
          onTapUp: (_) => _stopRecording(),
          onTapCancel: () => _stopRecording(),
          child: Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isRecording ? Colors.red : Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Text(
              isRecording ? '录音中' : '按住录音',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
