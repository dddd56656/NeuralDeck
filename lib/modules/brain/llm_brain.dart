import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
// 确保这里引用的是你查阅源码的那个包
import 'package:mediapipe_genai/mediapipe_genai.dart';
import 'brain_interface.dart';

/// [LLMBrain]
/// 适配最新版 MediaPipe GenAI API (LlmInferenceEngine)
class LLMBrain implements BrainInterface {
  bool _isInitialized = false;

  // 1. 修正：类名变更为 LlmInferenceEngine
  LlmInferenceEngine? _engine;

  // 必须与 pubspec.yaml 和 assets 实际文件名一致
  static const String _assetModelPath =
      'assets/models/gemma-2b-it-gpu-int4.bin';
  static const String _targetFileName = 'gemma-2b.bin';

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    print("🧠 Neural Engine: Initializing Kernel...");

    try {
      // 1. 拷贝模型到本地
      final newPath = await _copyModelToLocal();

      // 2. 修正：使用 .gpu 命名构造函数
      // 注意：sequenceBatchSize 是新必填项，通常设为 1 (单次对话)
      final options = LlmInferenceOptions.gpu(
        modelPath: newPath,
        maxTokens: 512,
        temperature: 0.7,
        topK: 40,
        randomSeed: 1024,
        sequenceBatchSize: 1, // 新增必填参数
      );

      // 3. 修正：直接同步构造，不需要 await createFromOptions
      _engine = LlmInferenceEngine(options);

      _isInitialized = true;
      print("🧠 Neural Engine: ONLINE (Gemma GPU Active).");
    } catch (e) {
      print("❌ Neural Engine Critical Failure: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeTarget(String inputTags) async {
    _checkStatus();
    print("🧠 Thinking (Reasoning): Analyzing '$inputTags'...");

    final prompt =
        '''
<start_of_turn>user
Role: Game Engine System.
Task: Analyze the input tags and generate RPG stats (0.0 to 1.0).
Input Tags: "$inputTags"
Rules:
1. If tags imply danger (weapon, fire), high ATK.
2. If tags imply tech (screen, wire), high MAG & DEF.
3. Output strictly valid JSON only. No markdown, no explanations.
Format: {"ATK": float, "DEF": float, "SPD": float, "MAG": float, "LUCK": float}
<end_of_turn>
<start_of_turn>model
''';

    try {
      // 4. 修正：API 只有 Stream 返回。我们需要把流聚合成一个完整的字符串。
      final stream = _engine!.generateResponse(prompt);

      // 将流中的所有片段拼接起来
      final fullResponse = await stream.join();

      // 清洗并解析 JSON
      final jsonString = _extractJson(fullResponse);
      return json.decode(jsonString);
    } catch (e) {
      print("⚠️ Reasoning Error: $e");
      // Fallback
      return {"ATK": 0.5, "DEF": 0.5, "SPD": 0.5, "MAG": 0.5, "LUCK": 0.5};
    }
  }

  @override
  Stream<String> generateLoreStream(String inputTags) {
    _checkStatus();
    print("🧠 Thinking (Generation): Drafting lore for '$inputTags'...");

    final prompt =
        '''
<start_of_turn>user
Task: Write a short, cryptic cyberpunk item description for an object identified as: "$inputTags".
Style: Gibson-esque, high-tech low-life, noir.
Limit: 2 sentences max.
Output: Just the description text.
<end_of_turn>
<start_of_turn>model
''';

    // 5. 修正：直接返回 Stream 即可，无需改动
    return _engine!.generateResponse(prompt);
  }

  void _checkStatus() {
    if (!_isInitialized || _engine == null) {
      throw Exception("Neural Engine not initialized! Call init() first.");
    }
  }

  Future<String> _copyModelToLocal() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$_targetFileName';
    final file = File(filePath);

    if (await file.exists()) {
      print("📂 Model found locally: $filePath");
      return filePath;
    }

    print("📂 Copying model from assets... (This may take 10-20s)");
    final byteData = await rootBundle.load(_assetModelPath);
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
    print("📂 Model copy complete.");
    return filePath;
  }

  String _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1) {
      return raw.substring(start, end + 1);
    }
    return raw;
  }

  @override
  void dispose() {
    // 6. 修正：安全关闭
    try {
      _engine?.dispose();
    } catch (e) {
      print("Dispose error: $e");
    }
    _engine = null;
    _isInitialized = false;
  }
}
