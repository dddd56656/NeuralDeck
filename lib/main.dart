import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart'; // 新增: 窗口管理

void main() async {
  // 修改: 变成 async
  WidgetsFlutterBinding.ensureInitialized();

  // === 桌面端窗口初始化 ===
  try {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 850), // 模拟手机/垂直终端的比例
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 无边框模式，更科幻
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    // 如果是在手机运行，这块会报错或跳过，不用管
    print("Not running on desktop or window_manager failed: $e");
  }

  runApp(const NeuralDeckApp());
}

class NeuralDeckApp extends StatelessWidget {
  const NeuralDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuralDeck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // === 赛博朋克暗黑主题 ===
        brightness: Brightness.dark,
        // ↓↓↓↓↓ 这里修复了你的那个方块问题 ↓↓↓↓↓
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFF00F0FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFFFF003C),
          surface: Color(0xFF121212),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.orbitronTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: const Color(0xFFE0E0E0),
            displayColor: const Color(0xFF00F0FF),
          ),
        ),
      ),
      home: const SystemBootScreen(),
    );
  }
}

class SystemBootScreen extends StatelessWidget {
  const SystemBootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 加一个简单的关闭按钮，因为我们把标题栏隐藏了
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              // 只有桌面端需要手动关闭
              // SystemNavigator.pop() 在 iOS/Android
              // exit(0) 在桌面
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.hub, size: 50, color: Color(0xFF00F0FF)),
            ),
            const SizedBox(height: 40),
            const Text(
              "NEURAL DECK",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "DESKTOP TERMINAL", // 改个字，体现你是桌面版
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[900],
                color: const Color(0xFFFF003C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
