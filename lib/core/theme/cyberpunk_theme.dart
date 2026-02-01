import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberpunkTheme {
  // 定义核心霓虹色
  static const Color neonBlue = Color(0xFF00F0FF); // 主色调
  static const Color neonRed = Color(0xFFFF003C); // 警告/高亮
  static const Color darkBg = Color(0xFF050505); // 纯黑背景
  static const Color surfaceBg = Color(0xFF121212); // 卡片背景
  // ✅ [新增] 修复报错：添加黑客终端绿
  // 这种高饱和度的绿色是 CRT 显示器的经典色
  static const Color neonGreen = Color(0xFF39FF14);

  static const Color backgroundBlack = Color(0xFF121212);
  // 获取全局主题配置
  static ThemeData get themeData {
    // 基础暗色主题
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: neonBlue,

      // 定义颜色方案
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonRed,
        surface: surfaceBg,
        error: neonRed,
      ),

      // 这里的字体需要根据 pubspec.yaml 实际引入情况调整
      textTheme: GoogleFonts.orbitronTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white.withOpacity(0.8), displayColor: neonBlue),

      // 定义 AppBar 默认样式
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: neonBlue),
      ),

      // 定义 Elevated Button 默认样式 (霓虹按钮)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceBg,
          foregroundColor: neonBlue,
          side: const BorderSide(color: neonBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 10,
          shadowColor: neonBlue.withOpacity(0.5),
        ),
      ),
    );
  }
}
