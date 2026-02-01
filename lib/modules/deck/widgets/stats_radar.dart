import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/cyberpunk_theme.dart';

class StatsRadar extends StatelessWidget {
  final Map<String, double> stats;
  final double size;

  const StatsRadar({super.key, required this.stats, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(stats),
        child: const Center(
          child: Icon(Icons.analytics, color: Colors.white12, size: 30),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> stats;

  _RadarPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(centerX, centerY);

    final outlinePaint = Paint()
      ..color = CyberpunkTheme.neonBlue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // 加粗一点线条

    final fillPaint = Paint()
      ..color = CyberpunkTheme.neonRed.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // 绘制3层网格背景
    for (int i = 1; i <= 3; i++) {
      _drawPolygon(canvas, centerX, centerY, radius * (i / 3), outlinePaint);
    }

    // 绘制数据层
    _drawDataShape(canvas, centerX, centerY, radius, fillPaint);
  }

  // 绘制正多边形 (背景网格)
  void _drawPolygon(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Paint paint,
  ) {
    final keys = stats.keys.toList();
    final angleStep = (2 * pi) / keys.length;
    final path = Path();

    for (int i = 0; i < keys.length; i++) {
      final angle = -pi / 2 + i * angleStep; // 从12点钟方向开始
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // 绘制不规则数据多边形
  void _drawDataShape(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Paint paint,
  ) {
    final keys = stats.keys.toList();
    final angleStep = (2 * pi) / keys.length;
    final path = Path();

    for (int i = 0; i < keys.length; i++) {
      final value = stats[keys[i]] ?? 0.0; // 获取能力值 (0.0 - 1.0)
      final angle = -pi / 2 + i * angleStep;
      // 核心公式：半径 * 数值 = 实际绘制点
      final x = cx + (r * value) * cos(angle);
      final y = cy + (r * value) * sin(angle);

      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // 描个红边，更有科技感
    final borderPaint = Paint()
      ..color = CyberpunkTheme.neonRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
