import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// ⚠️ 确保引用路径正确，指向你存放 Fllama 类的位置
import 'package:fllama/fllama.dart';
import 'brain_interface.dart';

class LLMBrain implements BrainInterface {
  bool _isInitialized = false;

  // 保存由 Fllama 返回的上下文 ID
  double? _contextId;

  // 模型文件名
  static const String _modelFileName = 'qwen.gguf';

  @override
  Future<void> init() async {
    if (_isInitialized && _contextId != null) return;
    print("🧠 (Qwen): Initializing Engine via Fllama...");

    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/$_modelFileName';
      final file = File(modelPath);

      // 1. 搬运模型 (Assets -> Local Storage)
      if (!file.existsSync() || file.lengthSync() < 100 * 1024 * 1024) {
        print("📦 正在释放 Qwen 模型...");
        try {
          final ByteData data = await rootBundle.load(
            'assets/models/$_modelFileName',
          );
          final List<int> bytes = data.buffer.asUint8List();
          await file.writeAsBytes(bytes, flush: true);
          print("✅ 模型释放完成: $modelPath");
        } catch (e) {
          throw Exception("❌ 模型释放失败，请检查 pubspec.yaml: $e");
        }
      }

      // 2. 初始化 Context
      // 根据你的 Fllama 源码，我们需要调用 initContext
      print("🚀 正在加载模型到内存...");
      final result = await Fllama.instance()!.initContext(
        modelPath,
        nCtx: 512, // 上下文长度，设小点省内存
        nThreads: 4, // 4线程适合大部分手机
        nGpuLayers: 0, // 强制 CPU 模式，最稳定
        emitLoadProgress: true, // 允许监听加载进度
      );

      print("🤖 Init Result: $result");

      // 3. 提取 Context ID
      // Fllama 通常会在返回的 Map 中包含 'contextId' 或类似字段
      // 如果 result 为空或者解析失败，说明初始化挂了
      if (result != null && result.containsKey('contextId')) {
        _contextId = (result['contextId'] as num).toDouble();
        print("✅ Qwen 引擎就绪, Context ID: $_contextId");
        _isInitialized = true;
      } else {
        // 尝试从 keys 猜测，如果 map 只有一个 entry 且是 double
        throw Exception("Fllama 初始化返回了无法识别的数据: $result");
      }
    } catch (e) {
      print("❌ 初始化失败: $e");
      rethrow;
    }
  }

  // ------------------------------------------------------
  // ⚡ 哈希属性 (保持 0 延迟秒开)
  // ------------------------------------------------------
  @override
  Future<Map<String, dynamic>> analyzeTarget(String inputTags) async {
    // 确保已初始化
    if (!_isInitialized) await init();

    print("⚡ Fast Stats: $inputTags");
    final seed = inputTags.codeUnits.fold(0, (p, c) => p + c);
    final random = Random(seed);
    double r() => (random.nextInt(90) + 10) / 100.0;

    // 模拟一点点计算感
    await Future.delayed(const Duration(milliseconds: 100));

    return {"ATK": r(), "DEF": r(), "SPD": r(), "MAG": r(), "LUCK": r()};
  }

  // ------------------------------------------------------
  // 📜 传说生成 (适配 Fllama Stream)
  // ------------------------------------------------------
  @override
  Stream<String> generateLoreStream(String inputTags) {
    if (!_isInitialized || _contextId == null) {
      // 如果没初始化，返回错误流
      return Stream.error("Brain not initialized");
    }

    // 1. 构造 Prompt
    final prompt =
        '''<|im_start|>system
Cyberpunk item analyzer. Brief.
<|im_end|>
<|im_start|>user
Analyze "$inputTags". Max 20 words.
<|im_end|>
<|im_start|>assistant
''';

    print("📝 发送 Prompt 到 Context $_contextId...");

    // 2. 创建 StreamController 来转发数据
    final controller = StreamController<String>();

    // 3. 订阅全局 Token 流
    // Fllama 的 onTokenStream 是一个全局广播流
    final StreamSubscription subscription = Fllama.instance()!.onTokenStream!
        .listen(
          (Map<Object?, dynamic> event) {
            // event 结构通常是: {'contextId': 1.0, 'token': 'xxx', ...}

            // 过滤：只处理当前 Context 的消息
            if (event['contextId'] == _contextId) {
              // 提取 token 文本
              final token = event['token'] as String?;
              if (token != null) {
                controller.add(token);
              }

              // 检查是否结束 (部分库会发 isEnd 或类似标志，或者 token 为空)
              // 这里我们简单处理：如果不报错就一直流，直到 UI 层通过 dispose 关掉它
              if (event['is_end'] == true || event['done'] == true) {
                controller.close();
              }
            }
          },
          onError: (e) {
            print("❌ Stream Error: $e");
            controller.addError(e);
          },
        );

    // 4. 触发生成 (Fire and Forget)
    // 注意：completion 是 Future，但我们会通过上面的 subscription 收到结果
    Fllama.instance()!
        .completion(
          _contextId!,
          prompt: prompt,
          nPredict: 64, // 限制长度
          emitRealtimeCompletion: true, // ✅ 关键：必须开启实时流
        )
        .then((_) {
          // completion Future 完成表示请求发送完毕，但流可能还在继续
          // 通常不需要在这里做太多操作
        })
        .catchError((e) {
          controller.addError(e);
          controller.close();
        });

    // 5. 当外部取消订阅时，清理资源
    controller.onCancel = () {
      subscription.cancel();
      // 可选：调用 stopCompletion
      // Fllama.instance()!.stopCompletion(contextId: _contextId!);
    };

    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    if (_contextId != null) {
      print("🛑 释放 Context $_contextId");
      await Fllama.instance()!.releaseContext(_contextId!);
      _contextId = null;
    }
    _isInitialized = false;
  }
}
