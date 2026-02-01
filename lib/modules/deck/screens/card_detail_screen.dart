import 'package:flutter/material.dart';
import '../../../core/theme/cyberpunk_theme.dart';
import '../../../core/services/brain_service.dart';
import '../../../core/services/tts_service.dart';
import '../widgets/holographic_card.dart';
import '../widgets/stats_radar.dart';

class CardDetailScreen extends StatefulWidget {
  final String rawText;
  final String translatedText;

  const CardDetailScreen({
    super.key,
    required this.rawText,
    required this.translatedText,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  String aiOutputBuffer = "";
  bool isAnalyzing = true;
  Map<String, double> stats = {
    'ATK': 0.1,
    'DEF': 0.1,
    'SPD': 0.1,
    'MAG': 0.1,
    'LUCK': 0.1,
  };

  final BrainService _brain = BrainService();
  final TTSService _tts = TTSService();

  @override
  void initState() {
    super.initState();
    _startFullAnalysis();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _startFullAnalysis() async {
    await _brain.init();
    final newStats = _brain.analyzeStats(widget.rawText);
    if (!mounted) return;
    setState(() => stats = newStats);

    final stream = _brain.generateLore(widget.rawText, widget.translatedText);
    stream.listen(
      (token) {
        if (!mounted) return;
        setState(() => aiOutputBuffer += token);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => isAnalyzing = false);
        _tts.speak(aiOutputBuffer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("数据解密完成"), // [汉化]
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.face_retouching_natural,
                    size: 80,
                    color: CyberpunkTheme.neonBlue,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAnalyzing ? "神经链路连接中..." : "分析报告生成完毕", // [汉化]
                    style: const TextStyle(
                      color: CyberpunkTheme.neonBlue,
                      letterSpacing: 1,
                    ),
                  ),
                  if (isAnalyzing)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          color: CyberpunkTheme.neonRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            HolographicCard(
              title: "目标解析", // [汉化]
              description: "数据源: ${widget.rawText}", // [汉化]
              child: Row(
                children: [
                  Expanded(flex: 4, child: StatsRadar(stats: stats, size: 140)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: SingleChildScrollView(
                        reverse: true,
                        child: Text(
                          aiOutputBuffer,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
