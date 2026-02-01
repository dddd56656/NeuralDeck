import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// [ImageLabelerService]
/// 视觉皮层 (Visual Cortex)
/// 修复了生命周期管理问题，支持热重启。
class ImageLabelerService {
  static final ImageLabelerService _instance = ImageLabelerService._internal();
  factory ImageLabelerService() => _instance;
  ImageLabelerService._internal();

  // 1. 去掉 final，改成可空 (?)。因为我们要允许它被创建、销毁、再创建。
  ImageLabeler? _imageLabeler;

  /// 内部 getter：智能获取标签器
  /// 如果当前是空的（第一次运行，或者刚被 dispose 过），就自动创建一个新的。
  ImageLabeler get _labeler {
    if (_imageLabeler == null) {
      print("👁️ Vision: Waking up visual cortex (Init)...");
      _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.6), // 建议提至 0.6，减少噪点
      );
    }
    return _imageLabeler!;
  }

  /// 核心能力：看图
  Future<List<String>> processImage(String imagePath) async {
    try {
      print("👁️ Vision: Analyzing visual features...");
      final inputImage = InputImage.fromFilePath(imagePath);

      // 2. 这里调用 getter (_labeler)，而不是直接调用变量
      // 这样保证了哪怕之前 dispose 过，这里也会自动重启
      final List<ImageLabel> labels = await _labeler.processImage(inputImage);

      if (labels.isEmpty) {
        // 返回空列表比返回 "Unknown Object" 更好，
        // 这样 BrainService 可以决定是自己编一段，还是提示没看清
        return [];
      }

      // 3. 结果优化：过滤 + 提取
      // 建议：只取前 3-5 个，太多了 Gemma 大脑会混乱
      final tagList = labels
          .take(5)
          .map((e) => e.label) // 这里取 label 文本
          .toList();

      print("👁️ Vision Result: $tagList");
      return tagList;
    } catch (e) {
      print("🔥 CRITICAL: Vision Module Error: $e");
      // 发生严重错误时返回空，避免 UI 崩溃
      return [];
    }
  }

  /// 释放显存/内存
  void dispose() {
    // 4. 安全关闭
    if (_imageLabeler != null) {
      print("👁️ Vision: Shutting down visual cortex.");
      _imageLabeler!.close(); // 关闭 Native 资源
      _imageLabeler = null; // 置空 Dart 引用，重置状态
    }
  }
}
