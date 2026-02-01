import 'dart:async'; // 引入 Async
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
  bool isAnalyzing = true; // 仅用于控制顶部图标动画

  // 订阅句柄 (用于页面销毁时取消流)
  StreamSubscription? _loreSubscription;

  Map<String, double> stats = {
    'ATK': 0.0,
    'DEF': 0.0,
    'SPD': 0.0,
    'MAG': 0.0,
    'LUCK': 0.0,
  };

  final BrainService _brain = BrainService();
  final TTSService _tts = TTSService();
  final ScrollController _scrollController = ScrollController(); // 控制文字滚动

  @override
  void initState() {
    super.initState();
    // 启动并行任务
    _igniteNeuralEngine();
  }

  @override
  void dispose() {
    // 🛑 必须操作：取消 AI 生成流，防止内存泄露
    _loreSubscription?.cancel();
    _tts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _igniteNeuralEngine() async {
    // 0. 快速检查初始化 (如果之前已经在 ScannerScreen 预热过，这里是瞬时的)
    await _brain.init();

    // Task A: 数值分析 (Reasoning) - 独立跑
    _brain
        .analyze(widget.rawText)
        .then((rawStats) {
          if (!mounted) return;
          final newStats = rawStats.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
          setState(() => stats = newStats);
        })
        .catchError((e) {
          print("Stats Error: $e");
        });

    // Task B: 传说生成 (Creative) - 独立跑，互不阻塞
    final stream = _brain.streamLore(widget.rawText);

    _loreSubscription = stream.listen(
      (token) {
        if (!mounted) return;
        setState(() {
          aiOutputBuffer += token;
        });
        // 自动滚动到底部
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      },
      onDone: () {
        if (!mounted) return;
        setState(() => isAnalyzing = false);
        _tts.speak(aiOutputBuffer);
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => aiOutputBuffer = ">> 神经链路中断: $e");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("DATA DECRYPTED"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: CyberpunkTheme.neonBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 顶部状态栏 (Header) ---
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: CyberpunkTheme.neonBlue.withOpacity(0.3),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 动态图标：分析中闪烁，分析完常亮
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isAnalyzing
                          ? [
                              BoxShadow(
                                color: CyberpunkTheme.neonBlue.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.hub, // 换成神经网络图标
                      size: 80,
                      color: isAnalyzing
                          ? Colors.white
                          : CyberpunkTheme.neonBlue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isAnalyzing ? "NEURAL LINK ACTIVE..." : "ANALYSIS COMPLETE",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      color: isAnalyzing
                          ? Colors.white70
                          : CyberpunkTheme.neonBlue,
                      letterSpacing: 2,
                    ),
                  ),
                  if (isAnalyzing)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 15,
                        left: 50,
                        right: 50,
                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        color: CyberpunkTheme.neonRed,
                      ),
                    ),
                ],
              ),
            ),

            // --- 全息卡片 (Content) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: HolographicCard(
                title: "TARGET ANALYSIS",
                description: widget.rawText.length > 50
                    ? "${widget.rawText.substring(0, 50)}..." // 截断过长的 Payload
                    : widget.rawText,
                child: Column(
                  // 改成 Column 布局以适应手机屏幕
                  children: [
                    // 1. 雷达图
                    SizedBox(
                      height: 200,
                      child: StatsRadar(stats: stats, size: 180),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),

                    // 2. 文本生成区 (Terminal 风格)
                    Container(
                      width: double.infinity,
                      height: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Text(
                          aiOutputBuffer.isEmpty
                              ? ">> Waiting for neural stream..."
                              : aiOutputBuffer,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 14,
                            color: CyberpunkTheme.neonGreen, // 终端绿
                            height: 1.5,
                            shadows: [
                              Shadow(
                                color: CyberpunkTheme.neonGreen,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
