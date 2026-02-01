import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mediapipe_genai/mediapipe_genai.dart';
import 'brain_interface.dart';

class LLMBrain implements BrainInterface {
  bool _isInitialized = false;
  LlmInferenceEngine? _engine;

  // 📡 模型下载地址
  // 这可以让国内设备无需梯子直接高速下载
  static const String _modelUrl =
      "https://hf-mirror.com/google/gemma-2b-it-gpu-int4/resolve/main/gemma-2b-it-gpu-int4.bin";
  static const String _targetFileName = 'gemma-2b-it-gpu-int4.bin';

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    print("🧠 Neural Engine: Initializing Kernel...");

    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/$_targetFileName';
      // 获取缓存目录（仅 CPU 模式需要）
      final cachePath = directory.path;

      final file = File(modelPath);

      if (!file.existsSync()) {
        print("⚠️ 神经核心丢失，开始下载...");
        await _downloadModel(modelPath);
        print("✅ 下载完成。");
      } else {
        print("📂 发现本地模型: $modelPath");
      }

      // 启动引擎
      _igniteEngine(modelPath, cachePath);

      _isInitialized = true;
    } catch (e) {
      print("❌ 核心启动失败: $e");
      rethrow;
    }
  }

  Future<void> _downloadModel(String savePath) async {
    // ✅ 修改点 2: 增加连接超时设置
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10), // 连接超时 10秒
        receiveTimeout: const Duration(minutes: 60), // 下载超时 60分钟
      ),
    );
    try {
      await dio.download(
        _modelUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(1);
            if (received % (total ~/ 20) < 100000) {
              print("⬇️ 下载中: $progress%");
            }
          }
        },
        options: Options(receiveTimeout: const Duration(minutes: 30)),
      );
    } catch (e) {
      final file = File(savePath);
      if (file.existsSync()) file.deleteSync();
      throw Exception("下载失败: $e");
    }
  }

  /// ✅ 核心修复：根据源码定义，区分构造参数
  void _igniteEngine(String modelPath, String cachePath) {
    LlmInferenceOptions options;
    try {
      print("🚀 尝试加载 GPU 模式 (High Performance)...");

      // [GPU 构造器]
      // 依据源码：需要 sequenceBatchSize，不需要 cacheDir
      options = LlmInferenceOptions.gpu(
        modelPath: modelPath,
        sequenceBatchSize: 1, // 必填
        maxTokens: 512,
        temperature: 0.7,
        topK: 40,
        randomSeed: 1024,
      );

      _engine = LlmInferenceEngine(options);
      print("✅ GPU 引擎上线。");
    } catch (e) {
      print("⚠️ GPU 失败 ($e)，切换至 CPU (Standard)...");

      // [CPU 构造器]
      // 依据源码：需要 cacheDir，不需要 sequenceBatchSize
      options = LlmInferenceOptions.cpu(
        modelPath: modelPath,
        cacheDir: cachePath, // 必填
        maxTokens: 512,
        temperature: 0.7,
        topK: 40,
        randomSeed: 1024,
      );

      _engine = LlmInferenceEngine(options);
      print("✅ CPU 引擎上线。");
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeTarget(String inputTags) async {
    _checkStatus();
    final prompt =
        '''<start_of_turn>user
Format: JSON {"ATK":0.0-1.0,"DEF":0.0-1.0,"SPD":0.0-1.0,"MAG":0.0-1.0,"LUCK":0.0-1.0}
Input: "$inputTags"
Output: JSON only.
<end_of_turn>
<start_of_turn>model
''';

    try {
      final responseStream = _engine!.generateResponse(prompt);
      final fullText = await responseStream.join();
      return json.decode(_extractJson(fullText));
    } catch (e) {
      return {"ATK": 0.5, "DEF": 0.5, "SPD": 0.5, "MAG": 0.5, "LUCK": 0.5};
    }
  }

  @override
  Stream<String> generateLoreStream(String inputTags) {
    _checkStatus();
    final prompt =
        '''<start_of_turn>user
Description for "$inputTags" (Cyberpunk style, max 20 words).
<end_of_turn>
<start_of_turn>model
''';
    return _engine!.generateResponse(prompt);
  }

  void _checkStatus() {
    if (!_isInitialized || _engine == null) {
      throw Exception("Neural Engine not initialized!");
    }
  }

  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1) return raw.substring(start, end + 1);
    return "{}";
  }

  @override
  void dispose() {
    _engine?.dispose();
    _engine = null;
    _isInitialized = false;
  }
}
