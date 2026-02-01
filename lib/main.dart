import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/local_db.dart';
import 'core/services/brain_service.dart';
import 'core/theme/cyberpunk_theme.dart';
import 'modules/deck/screens/scanner_screen.dart';
import 'modules/deck/screens/card_detail_screen.dart';

void main() {
  // 1. 移除 async，移除这里的 await 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 锁定竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. 立即启动 UI，不等待
  runApp(const NeuralDeckApp());
}

class NeuralDeckApp extends StatelessWidget {
  const NeuralDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuralDeck',
      debugShowCheckedModeBanner: false,
      theme: CyberpunkTheme.themeData,
      // 3. 将首页指向新的 SplashScreen
      home: const SplashScreen(),
    );
  }
}

/// [新增] 启动页
/// 负责在后台执行耗时的初始化任务，同时在前台显示 Loading 动画
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = "INITIALIZING SYSTEM...";
  double? _progressValue; // null 表示不确定进度的动画

  @override
  void initState() {
    super.initState();
    // 页面渲染完成后，立即执行初始化
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      // 阶段 1: 数据库
      setState(() => _statusText = "MOUNTING MEMORY (SQLITE)...");
      await LocalDB.instance.database;

      // 阶段 2: 神经网络 (最耗时)
      setState(() {
        _statusText = "INSTALLING NEURAL CORE...\n(FIRST RUN MAY TAKE 20s)";
      });

      // 让 UI 呼吸一下，避免渲染锁死
      await Future.delayed(const Duration(milliseconds: 100));

      await BrainService().init();

      // 阶段 3: 完成
      setState(() => _statusText = "SYSTEM ONLINE.");
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 跳转到主界面 (使用 pushReplacement 销毁启动页)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MobileTerminalScreen()),
      );
    } catch (e) {
      setState(() {
        _statusText = "BOOT FAILURE: $e\nPLEASE RESTART.";
      });
      print("CRITICAL: Services failed to start: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 确保背景是黑的
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 赛博风格的 Logo 或图标
            const Icon(Icons.hub, size: 80, color: Color(0xFF00F0FF)),
            const SizedBox(height: 30),

            // 进度条
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: const Color(0xFF121212),
                color: const Color(0xFFFF003C),
              ),
            ),
            const SizedBox(height: 20),

            // 状态文字
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Color(0xFF00F0FF),
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 以下保持原来的 MobileTerminalScreen 逻辑不变 ---

class MobileTerminalScreen extends StatefulWidget {
  const MobileTerminalScreen({super.key});

  @override
  State<MobileTerminalScreen> createState() => _MobileTerminalScreenState();
}

class _MobileTerminalScreenState extends State<MobileTerminalScreen> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const _LogsPage(),
    const ScannerScreen(),
    const _DiagnosticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "神经终端 v1.0",
          style: TextStyle(letterSpacing: 2, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.hub, color: Color(0xFF00F0FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.3)),
          ),
          color: Colors.black,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00F0FF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.history), label: '历史记录'),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner, size: 32),
              label: '扫描',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: '系统诊断'),
          ],
        ),
      ),
    );
  }
}

class _LogsPage extends StatefulWidget {
  const _LogsPage();

  @override
  State<_LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<_LogsPage> {
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = LocalDB.instance.queryAll('cards');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "暂无数据记录",
              style: TextStyle(color: Colors.grey, letterSpacing: 2),
            ),
          );
        }

        final logs = snapshot.data!;
        return ListView.builder(
          itemCount: logs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final log = logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF00F0FF).withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.data_object,
                  color: Colors.grey,
                  size: 20,
                ),
                title: Text(
                  (log['translated_text'] as String? ?? '未知目标')
                      .split('\n')
                      .first,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "编号: ${log['id']} | ${DateTime.fromMillisecondsSinceEpoch(log['created_at'] as int).toString().split('.')[0]}",
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                dense: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardDetailScreen(
                        rawText: log['raw_text'],
                        translatedText: log['translated_text'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _DiagnosticsPage extends StatelessWidget {
  const _DiagnosticsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Color(0xFFFF003C)),
          SizedBox(height: 16),
          Text("系统状态监控", style: TextStyle(letterSpacing: 2, fontSize: 16)),
          SizedBox(height: 8),
          Text(
            "CPU核心: 正常运转\n神经内存: 状态极佳\n网络连接: 已断开 (离线模式)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
