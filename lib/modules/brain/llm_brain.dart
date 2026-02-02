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
    // 1. 基础检查
    if (!_isInitialized || _contextId == null) {
      print("❌ 大脑未初始化，尝试重新初始化...");
      // 可以在这里尝试重新 init()，或者直接报错
      return Stream.error("Brain not initialized");
    }

    // 🔴 [重点修改] 抛弃所有复杂的 <|system|> 标签
    // 改用“强制续写”模式。
    // 比如：Input="刀", Prompt="这是一把赛博朋克风格的刀，它的特点是"
    // 模型看到这个结尾，不得不把后面的话补全。
    final prompt =
        'Describe $inputTags in a Cyberpunk style. The $inputTags is';

    print("📝 发送强制续写 Prompt: [$prompt] (Context ID: $_contextId)");

    final controller = StreamController<String>();

    // 2. 监听流 (保持不变，加了点日志)
    final sub = Fllama.instance()!.onTokenStream!.listen(
      (event) {
        // 只处理当前 Context 的消息
        if (event['contextId'] == _contextId) {
          final token = event['token'] as String?;

          // 🔍 调试日志：看看到底有没有字
          if (token != null && token.isNotEmpty) {
            print("🔤 AI吐字: [$token]");
            controller.add(token);
          } else {
            // 有时候空包也是正常的，忽略即可
          }

          // 结束判断
          if (event['is_end'] == true || event['done'] == true) {
            print("✅ 生成结束 (Done Signal)");
            controller.close();
          }
        }
      },
      onError: (e) {
        print("❌ 流监听报错: $e");
        controller.addError(e);
      },
    );

    // 3. 发送请求 (参数微调)
    Fllama.instance()!
        .completion(
          _contextId!,
          prompt: prompt,
          nPredict: 50, // 强制定长 50 个 token
          temperature: 0.8, // 温度稍微高点，让它活跃点
          topK: 40, // 标准采样参数
          topP: 0.9, // 标准采样参数
          emitRealtimeCompletion: true, // 必须开启实时流
        )
        .then((_) {
          print("📡 请求已发送给底层引擎");
        })
        .catchError((e) {
          print("❌ 请求发送失败: $e");
          controller.addError(e);
          controller.close();
        });

    // 4. 清理逻辑
    controller.onCancel = () {
      print("🛑 用户取消了生成");
      sub.cancel();
      // 可选：Fllama.instance()!.stopCompletion(contextId: _contextId!);
    };

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
