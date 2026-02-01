// [Google CTO Standard]
// 这里的 Interface 遵循单一职责原则 (SRP)。
// 它只定义“大脑能做什么”，不关心“大脑怎么做”。
// 所有的返回值都被改为 Future/Stream，因为 AI 推理本质上是 IO 密集型或计算密集型的异步操作。

abstract class BrainInterface {
  /// 初始化大脑
  /// 真实场景：加载 1.5GB 的 .bin 模型文件到内存，预热 GPU。
  Future<void> init();

  /// 核心能力 1: 认知分析 (Reasoning)
  /// Input: inputTags (视觉标签，如 "Cat, Animal")
  /// Output: 完整的 JSON 结构化数据 (属性数值)
  Future<Map<String, dynamic>> analyzeTarget(String inputTags);

  /// 核心能力 2: 创意写作 (Generation)
  /// Input: inputTags (视觉标签)
  /// Output: 流式文本 (Stream)，用于实现打字机效果，降低用户的感知延迟 (Perceived Latency)。
  Stream<String> generateLoreStream(String inputTags);

  /// 销毁资源，防止内存泄漏 (OOM)
  void dispose();
}
