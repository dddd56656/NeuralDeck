import '../../modules/brain/brain_interface.dart';
import '../../modules/brain/llm_brain.dart';
// import '../../modules/brain/heuristic_brain.dart'; // 备用

class BrainService {
  static final BrainService _instance = BrainService._internal();
  factory BrainService() => _instance;
  BrainService._internal();

  late BrainInterface _engine;

  Future<void> init() async {
    // 🔥 切换为 LLM 大脑
    _engine = LLMBrain();

    // 初始化可能需要 1-2 秒，但这对于 Qwen-0.5B 来说很快
    await _engine.init();
  }

  Map<String, double> analyzeStats(String text) => _engine.analyzeStats(text);
  Stream<String> generateLore(String text, String tr) =>
      _engine.generateLore(text, tr);
}
