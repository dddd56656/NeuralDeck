import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fllama/fllama.dart';
import 'brain_interface.dart';

class LLMBrain implements BrainInterface {
  bool _isInitialized = false;
  double? _contextId;

  // ✅ 1. 确保文件名一致
  static const String _modelFileName = 'tinyllama.gguf';

  @override
  Future<void> init() async {
    if (_isInitialized && _contextId != null) return;
    print("🧠 (TinyLlama): Init...");

    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/$_modelFileName';
      final file = File(modelPath);

      // 搬运模型 (Assets -> App Doc Dir)
      if (!file.existsSync()) {
        print("📦 正在释放 TinyLlama 模型 (600MB+)...");
        try {
          final ByteData data = await rootBundle.load(
            'assets/models/$_modelFileName',
          );
          final List<int> bytes = data.buffer.asUint8List();
          await file.writeAsBytes(bytes, flush: true);
          print("✅ 模型释放完成");
        } catch (e) {
          throw Exception(
            "❌ 找不到 assets/models/tinyllama.gguf，请检查 pubspec.yaml: $e",
          );
        }
      }

      // 初始化引擎
      print("🚀 Loading Engine...");
      final result = await Fllama.instance()!.initContext(
        modelPath,
        nCtx: 2048, // TinyLlama 支持 2048
        nThreads: 4, // 4线程
        nGpuLayers: 0, // 强制 CPU
        emitLoadProgress: true,
      );

      if (result != null && result.containsKey('contextId')) {
        _contextId = (result['contextId'] as num).toDouble();
        print("✅ Engine Ready! ID: $_contextId");
        _isInitialized = true;
      } else {
        throw Exception("Init failed: $result");
      }
    } catch (e) {
      print("❌ Init Error: $e");
      rethrow;
    }
  }

  // 这里的 analyzeTarget 保持不变...
  @override
  Future<Map<String, dynamic>> analyzeTarget(String inputTags) async {
    if (!_isInitialized) await init();
    final seed = inputTags.codeUnits.fold(0, (p, c) => p + c);
    final rnd = Random(seed);
    double r() => (rnd.nextInt(90) + 10) / 100.0;
    await Future.delayed(const Duration(milliseconds: 100));
    return {"ATK": r(), "DEF": r(), "SPD": r(), "MAG": r(), "LUCK": r()};
  }

  @override
  Stream<String> generateLoreStream(String inputTags) {
    if (!_isInitialized || _contextId == null)
      return Stream.error("Brain not initialized");

    // ✅ 2. TinyLlama 专用 Prompt 格式 (非常重要！)
    // 必须严格遵守 <|system|> ... </s> 这种格式
    final prompt =
        '''<|system|>
You are a Cyberpunk item analyzer. Describe the item in 1 sentence.</s>
<|user|>
Item: "$inputTags"</s>
<|assistant|>''';

    print("📝 Sending Prompt...");
    final controller = StreamController<String>();

    final sub = Fllama.instance()!.onTokenStream!.listen((event) {
      if (event['contextId'] == _contextId) {
        final token = event['token'] as String?;
        if (token != null) {
          // 打印到控制台看看有没有反应
          stdout.write(token);
          controller.add(token);
        }
        if (event['is_end'] == true || event['done'] == true) {
          print("\n✅ Done");
          controller.close();
        }
      }
    }, onError: controller.addError);

    Fllama.instance()!
        .completion(
          _contextId!,
          prompt: prompt,
          nPredict: 50,
          emitRealtimeCompletion: true,
        )
        .catchError((e) {
          controller.addError(e);
          controller.close();
        });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    if (_contextId != null) {
      await Fllama.instance()!.releaseContext(_contextId!);
      _contextId = null;
    }
    _isInitialized = false;
  }
}
