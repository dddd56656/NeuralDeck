// 文件: lib/modules/brain/brain_interface.dart

// 定义所有大脑必须具备的能力标准
abstract class BrainInterface {
  // 初始化大脑 (加载模型或预热算法)
  Future<void> init();

  // 核心能力 1: 根据文本瞬间计算属性 (用于雷达图)
  Map<String, double> analyzeStats(String text);

  // 核心能力 2: 根据文本生成背景故事 (流式输出)
  Stream<String> generateLore(String text, String translatedText);

  // 销毁资源
  void dispose();
}
