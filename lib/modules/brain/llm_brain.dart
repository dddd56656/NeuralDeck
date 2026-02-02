import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mediapipe_genai/mediapipe_genai.dart';

import 'brain_interface.dart';

/// 遵循谷歌标准的 MediaPipe 本地推理大脑
class LLMBrain implements BrainInterface {
  LlmInferenceEngine? _engine;
  bool _isInitialized = false;

  // 模型文件名，对应资产目录
  static const String _modelName = 'tinyllama.tflite'; // 实际为你下载的 .task 文件

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    print("🧠 [Brain] 正在初始化谷歌 MediaPipe 推理引擎...");

    try {
      final directory = await getApplicationDocumentsDirectory();

      // 1. 资源就位：MediaPipe 引擎需要物理路径
      final modelFile = File('${directory.path}/$_modelName');
      if (!modelFile.existsSync()) {
        print("📦 [Brain] 正在提取模型资源到本地存储...");
        final data = await rootBundle.load('assets/models/$_modelName');
        await modelFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }

      // 2. 缓存目录：用于存放 KV Cache 和中间张量
      final cacheDir = Directory('${directory.path}/llm_cache');
      if (!cacheDir.existsSync()) await cacheDir.create();

      // 3. 硬件配置：红米 Note 14 Pro 具备 Mali-G615 GPU
      // 我们优先使用 GPU 模式以获得更快的生成速度
      final options = LlmInferenceOptions.gpu(
        modelPath: modelFile.path,
        maxTokens: 512, // 限制最大生成长度
        temperature: 0.8, // 控制创造力
        topK: 40, // 词频过滤
        sequenceBatchSize: 1, // 移动端单例批处理
      );

      // 4. 实例化引擎
      _engine = LlmInferenceEngine(options);

      _isInitialized = true;
      print("✅ [Brain] MediaPipe Engine 已就绪 (GPU 加速已激活)");
    } catch (e) {
      print("❌ [Brain] 初始化失败: $e");
      _isInitialized = false;
    }
  }

  @override
  Stream<String> generateLoreStream(String inputTags) async* {
    if (!_isInitialized || _engine == null) {
      await init();
    }

    // 清理输入，构造符合模型预期的 Prompt
    final String prompt = _buildPrompt(inputTags);
    print("📝 [Brain] 发送指令至本地模型: $prompt");

    try {
      // 🚀 直接调用源码中的 generateResponse 接口
      // 该接口返回的是 Stream<String>，完美契合 Flutter 的流式 UI
      yield* _engine!.generateResponse(prompt).handleError((error) {
        print("❌ [Brain] 推理流异常: $error");
        return " [Link Error] ";
      });
    } catch (e) {
      print("❌ [Brain] 推理崩溃: $e");
      yield " [Neural Link Failure] ";
    }
  }

  /// 构造对话模板（针对 Gemma/TinyLlama 优化）
  String _buildPrompt(String input) {
    return "<|user|>\nAnalyze this cyberpunk item: $input<|assistant|>\n";
  }

  @override
  Future<Map<String, dynamic>> analyzeTarget(String inputTags) async => {};

  @override
  void dispose() {
    // 🚀 遵循源码要求：释放所有原生资源，防止 NDK 内存泄漏
    _engine?.dispose();
    _engine = null;
    _isInitialized = false;
    print("🧹 [Brain] 原生资源已释放");
  }
}
