import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于控制状态栏颜色
import 'package:google_fonts/google_fonts.dart';

void main() {
  // 确保系统绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 强制竖屏 (手机 App 的常规操作)
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
      theme: ThemeData(
        // === 赛博朋克移动端主题 ===
        brightness: Brightness.dark,
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
  int _currentIndex = 1; // 默认选中中间的“生成”页面

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 顶部简单的状态栏
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("NEURAL DECK", style: TextStyle(letterSpacing: 3, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.hub, color: Color(0xFF00F0FF)),
            onPressed: () {}, // 这里以后放设置
          )
        ],
      ),
      
      // 中间的主体内容
      body: Center(
        child: _buildBody(),
      ),

      // 底部导航栏 (Bottom Navigation)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.3))),
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
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'LOGS'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner, size: 32), label: 'SCAN'), // 中间大一点
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'DIAG'),
          ],
        ),
      ),
    );
  }

  // 简单的页面切换逻辑
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const Text("HISTORY LOGS\n[Offline]", textAlign: TextAlign.center);
      case 1:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 全息光圈
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.4), blurRadius: 30)
                ],
              ),
              child: const Icon(Icons.touch_app, size: 60, color: Color(0xFF00F0FF)),
            ),
            const SizedBox(height: 40),
            const Text("SYSTEM READY", style: TextStyle(fontSize: 20, letterSpacing: 5)),
            const SizedBox(height: 10),
            const Text("Tap 'SCAN' to Initialize", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );
      case 2:
        return const Text("DIAGNOSTICS\n[No Data]", textAlign: TextAlign.center);
      default:
        return Container();
    }
  }
}