import 'package:flutter/material.dart';
import '../../../core/theme/cyberpunk_theme.dart';

class HolographicCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const HolographicCard({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CyberpunkTheme.surfaceBg.withOpacity(0.9),
        border: Border.all(color: CyberpunkTheme.neonBlue, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CyberpunkTheme.neonBlue.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisSize.min 告诉 Column：内容有多少，我就多高，不要试图撑满屏幕
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(color: CyberpunkTheme.neonBlue, height: 20),

          // === 🔥 核心修改 🔥 ===
          // 之前这里是 Expanded(child: child)，会导致在滚动视图中崩溃。
          // 现在直接放 child，让内容自然撑开高度。
          child,

          // ====================
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: CyberpunkTheme.neonBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: CyberpunkTheme.neonBlue, blurRadius: 10)],
          ),
        ),
        const Icon(Icons.hub, size: 18, color: CyberpunkTheme.neonRed),
      ],
    );
  }
}
