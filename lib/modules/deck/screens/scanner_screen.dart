import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import 'card_detail_screen.dart';
import '../../vision/ocr_processor.dart';
import '../../vision/image_labeler.dart';
import '../../../core/services/local_db.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool isScanning = false;
  String? errorMessage;

  // 视觉处理器
  // 注意：OCR 目前不是单例，所以需要页面自己管理
  final OcrProcessor _ocr = OcrProcessor();

  // 注意：ImageLabeler 是单例，我们只引用它，不拥有它
  final ImageLabelerService _imageLabeler = ImageLabelerService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocr.dispose();
    // 🛑 修正点：绝对不要在这里调用 _imageLabeler.dispose()！
    // 因为它是全局单例，你把它关了，下次进页面就崩了。
    // 让 Service 自己管理生命周期，或者在 App 退出时统一关闭。
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => errorMessage = "视觉传感器离线 (模拟器模式)");
        return;
      }
      _controller = CameraController(
        cameras.first,
        // 💡 CTO 提示：ResolutionPreset.medium (720p) 是最佳选择
        // 不要开到 high/max，那会显著拖慢 OCR 和 ML 的推理速度，且准确率提升微乎其微。
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // 显式指定格式更稳妥
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => errorMessage = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = "视觉模块启动失败: $e");
    }
  }

  Future<void> _onScanPressed() async {
    if (isScanning) return;
    setState(() => isScanning = true);

    try {
      // 1. 捕获图像
      String? imagePath;
      if (_controller != null && _controller!.value.isInitialized) {
        // 💡 禁用快门声以增强沉浸感 (如果系统允许)
        final XFile imageFile = await _controller!.takePicture();
        imagePath = imageFile.path;
      }

      // 2. 并行处理 (Parallel Execution)
      List<String> visualTags = [];
      String ocrText = "";

      if (imagePath != null) {
        // 使用 Future.wait 让 CPU 多核并行跑两个模型
        final results = await Future.wait([
          _imageLabeler.processImage(imagePath), // Task 1: 识物
          _ocr.scanImage(imagePath), // Task 2: 识字
        ]);

        // 安全转型
        visualTags = results[0] as List<String>;
        ocrText = results[1] as String;
      } else {
        // 模拟器 Fallback
        await Future.delayed(const Duration(seconds: 1));
        visualTags = ["Cyberpunk Terminal", "Glitch"];
        ocrText = "NO_DATA_DETECTED";
      }

      // 3. 数据融合 (Data Fusion)
      // 这里的 payload 格式是Prompt Engineering的关键素材
      final String payload =
          "Image Analysis:\nTags: ${visualTags.join(', ')}\nOCR: $ocrText";

      // 4. 存证 (异步写入，不需要 await 阻塞 UI 跳转，Fire and forget)
      LocalDB.instance
          .insertData('cards', {
            'raw_text': payload,
            'translated_text': "等待神经链路分析...",
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'ai_rating': '{}',
          })
          .then((_) => print("💾 Data persisted to local cortex."));

      if (!mounted) return;

      // 5. 传输 (Handover)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailScreen(
            rawText: payload,
            translatedText: "", // 占位符，交给 Gemma 生成
          ),
        ),
      );
    } catch (e) {
      print("⚠️ Scan Error: $e");
      setState(() => errorMessage = "扫描中断: 系统过载");
    } finally {
      if (mounted) setState(() => isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 错误处理 UI
    if (errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: CyberpunkTheme.neonRed),
          ),
        ),
      );
    }

    // 加载中 UI
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: CyberpunkTheme.neonBlue),
      );
    }

    // 主界面
    return Scaffold(
      body: Stack(
        children: [
          // 1. 相机预览层
          SizedBox.expand(child: CameraPreview(_controller!)),

          // 2. 扫描框层 (Overlay)
          Center(
            child: Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(
                  color: CyberpunkTheme.neonBlue.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.neonBlue.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // 3. 交互层 (FAB)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: FloatingActionButton.large(
                backgroundColor: CyberpunkTheme.neonRed,
                onPressed: _onScanPressed,
                child: isScanning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.camera_alt, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
