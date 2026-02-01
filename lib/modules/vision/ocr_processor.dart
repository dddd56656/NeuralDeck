import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrProcessor {
  // 获取文本识别器实例 (支持拉丁字母)
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // 核心方法：扫描图片
  Future<String> scanImage(String imagePath) async {
    try {
      print("OCR Analyzing: $imagePath");

      // 1. 将文件路径转换为 ML Kit 能懂的 InputImage
      final inputImage = InputImage.fromFilePath(imagePath);

      // 2. 调用 Google ML Kit 进行推理
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // 3. 提取结果
      String resultText = recognizedText.text;

      // 简单的过滤逻辑：如果没识别到字，返回提示
      if (resultText.trim().isEmpty) {
        return "UNKNOWN_OBJECT";
      }

      // 简单处理：把换行符换成空格，方便显示
      // 实际业务中这里会做正则匹配 (Regex) 来提取攻击力/防御力
      return resultText.replaceAll("\n", " ");
    } catch (e) {
      print("OCR Error: $e");
      return "DATA_CORRUPTED";
    }
  }

  // 释放资源，防止内存泄漏
  void dispose() {
    _textRecognizer.close();
  }
}
