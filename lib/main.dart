// 文件: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/local_db.dart';
import 'core/services/brain_service.dart';
import 'core/theme/cyberpunk_theme.dart';
import 'modules/deck/screens/scanner_screen.dart';
import 'modules/deck/screens/card_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await LocalDB.instance.database;
    await BrainService().init();
  } catch (e) {
    print("CRITICAL: Services failed to start: $e");
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      home: const MobileTerminalScreen(),
    );
  }
}

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
          "神经终端 v1.0", // [汉化]
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
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: '历史记录',
            ), // [汉化]
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner, size: 32),
              label: '扫描',
            ), // [汉化]
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: '系统诊断',
            ), // [汉化]
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
            ), // [汉化]
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
          Text(
            "系统状态监控",
            style: TextStyle(letterSpacing: 2, fontSize: 16),
          ), // [汉化]
          SizedBox(height: 8),
          Text(
            "CPU核心: 正常运转\n神经内存: 状态极佳\n网络连接: 已断开 (离线模式)", // [汉化] 强调离线
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
