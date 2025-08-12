import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:voice/data/notifiers.dart';
import 'dart:math';

class MicPage extends StatefulWidget {
  const MicPage({super.key});
  @override
  State<MicPage> createState() => _MicPageState();
}

class _MicPageState extends State<MicPage> {
  // _recorderInitialized 和 _modelLoaded 用来通知 UI 
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderInitialized = false;

  final List<double> _pcmData = [];
  StreamSubscription? _audioStreamSubscription;

  late Interpreter _interpreter;
  bool _modelLoaded = false;

  String _text = '';

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
    print(data);
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

    // print('模型推理结果 embedding: ${output[0]}');
    final res = _compare(output[0]);

    setState(() {
      _text = res;  
    });
  }

  String _compare(List<double> currEmb) {
    const threshold = 1.0;
    double minDist = double.infinity;
    double currDist = 0.0;
    String predRes = "";
    bool notFound = true;
    for (var entry in voicesNotifier.value.entries) {
      currDist = euclideanDistance(entry.value, currEmb);
      if (currDist <= threshold && currDist < minDist) {
        notFound = false;
        minDist = currDist;
        predRes = entry.key;
      }
    }

    if (notFound) {
      _showSaveDialog(currEmb);
      return "Not Found";
    }

    return predRes;
  }

  void _showSaveDialog(List<double> embedding) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("新人物"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "请输入人物名称",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 取消
              },
              child: const Text("取消"),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  bool exits = voicesNotifier.value.containsKey(name);
                  if (exits) {
                    final shouldOverride = await showDialog<bool>(
                      context: context, 
                      builder:(context) => AlertDialog(
                        title: Text('覆盖已有的人脸？'),
                        content: Text('名称 "$name" 已存在，是否覆盖原有数据？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('覆盖'),
                          ),
                        ],
                      )
                    );

                    if (shouldOverride != true) return; 
                  }
                  voicesNotifier.value[name] = embedding;
                }

                navigator.pop();
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    );
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isRecording ? Colors.redAccent : Colors.deepPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isRecording ? Colors.redAccent.withOpacity(0.6) : Colors.deepPurple.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 3,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  isRecording ? '录音中...' : '按住录音',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 150, // 限制最大高度，防止占用太多空间
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _text.isEmpty ? '识别结果' : _text,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double euclideanDistance(List<double> e1, List<double> e2) {
  double sum = 0.0;
  for (int i = 0; i < e1.length; i++) {
    sum += pow((e1[i] - e2[i]), 2);
  }
  return sqrt(sum);
}
