import 'dart:async';
import '../../modules/brain/brain_interface.dart';
import '../../modules/brain/llm_brain.dart';

/// 🧠 BrainService (Enhanced)
/// 增加了状态管理和初始化守卫，防止在模型未就绪时调用导致崩溃。
class BrainService {
  static final BrainService _instance = BrainService._internal();
  factory BrainService() => _instance;
  BrainService._internal();

  // 依赖注入点：允许测试时替换 Mock 引擎
  // 默认为 LLMBrain，但可以通过 setEngine 替换
  BrainInterface _engine = LLMBrain();

  // 状态锁：用于防止重复初始化
  Completer<void>? _initCompleter;

  // 简单的状态标记
  bool get isReady => _initCompleter != null && _initCompleter!.isCompleted;

  /// 初始化服务 (幂等设计：多次调用不会重复执行)
  Future<void> init() async {
    // 1. 如果已经在初始化中或已完成，直接返回现有的 Future
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      print("🔧 BrainService: Starting Engine sequence...");
      await _engine.init();

      // 标记完成
      _initCompleter!.complete();
      print("🔧 BrainService: Engine Ready.");
    } catch (e) {
      // 2. 关键修正：初始化失败必须抛出，或者重置状态允许重试
      print("🔥 CRITICAL: Brain Init Failed: $e");
      _initCompleter!.completeError(e); // 通知等待者出错了
      _initCompleter = null; // 重置，允许下次重试
      rethrow; // 让 UI 层知道出事了（比如显示重试按钮）
    }
  }

  /// 代理方法：分析目标 (带守卫)
  Future<Map<String, dynamic>> analyze(String inputTags) async {
    // 3. 自动守卫：如果由于某种原因没初始化，先尝试初始化
    await _ensureInitialized();
    return await _engine.analyzeTarget(inputTags);
  }

  /// 代理方法：生成传说 (带守卫)
  Stream<String> streamLore(String inputTags) async* {
    // Stream 的守卫稍微复杂点，需要 yield
    await _ensureInitialized();
    yield* _engine.generateLoreStream(inputTags);
  }

  /// 内部辅助：确保引擎就绪
  Future<void> _ensureInitialized() async {
    if (_initCompleter == null) {
      // 如果还没人调用过 init，这里自动触发
      print("⚠️ Warning: Lazy initializing BrainService...");
      await init();
    } else {
      // 如果正在初始化，等待它完成
      await _initCompleter!.future;
    }
  }

  /// 仅用于测试：替换引擎
  void setMockEngine(BrainInterface mock) {
    _engine = mock;
  }

  void dispose() {
    _engine.dispose();
    _initCompleter = null;
  }
}
