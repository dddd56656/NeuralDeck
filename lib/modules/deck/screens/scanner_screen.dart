import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import 'card_detail_screen.dart';
import '../../vision/ocr_processor.dart';
import '../../vision/translator.dart';
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
  final OcrProcessor _ocr = OcrProcessor();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => errorMessage = "未检测到视觉传感器 (是模拟器吗?)"); // [汉化]
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
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
      String rawText;
      if (_controller != null && _controller!.value.isInitialized) {
        final XFile imageFile = await _controller!.takePicture();
        rawText = await _ocr.scanImage(imageFile.path);
      } else {
        await Future.delayed(const Duration(seconds: 1));
        // [汉化] 模拟数据改为中文
        rawText = "Cyberpunk 2077\n荒坂公司资产\n状态: 正常";
      }

      if (rawText.isEmpty) rawText = "未识别到有效文本"; // [汉化]

      final String translatedText = await Translator.instance.translate(
        rawText,
      );

      await LocalDB.instance.insertData('cards', {
        'raw_text': rawText,
        'translated_text': translatedText,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'ai_rating': '{}',
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailScreen(
            rawText: rawText,
            translatedText: translatedText,
          ),
        ),
      );
    } catch (e) {
      setState(() => errorMessage = "扫描中断: $e");
    } finally {
      if (mounted) setState(() => isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: CyberpunkTheme.neonRed,
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _onScanPressed,
                icon: const Icon(Icons.bug_report),
                label: const Text("启用模拟数据链路"), // [汉化]
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: CyberpunkTheme.neonBlue),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
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
              ),
            ),
          ),
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
