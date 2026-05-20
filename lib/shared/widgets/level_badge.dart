import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(level);
    final icon = _levelIcon(level);

    return SizedBox(
      width: 74,
      height: 74,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.65)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 18,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              level,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    return switch (level.toLowerCase()) {
      'bronze' => const Color(0xFFCD7F32),
      'prata' => const Color(0xFFC7D0DD),
      'ouro' => AppTheme.warning,
      'diamante' => AppTheme.secondary,
      'lenda' => AppTheme.primary,
      _ => AppTheme.primary,
    };
  }

  IconData _levelIcon(String level) {
    return switch (level.toLowerCase()) {
      'bronze' => Icons.military_tech_rounded,
      'prata' => Icons.workspace_premium_rounded,
      'ouro' => Icons.emoji_events_rounded,
      'diamante' => Icons.diamond_rounded,
      'lenda' => Icons.auto_awesome_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }
}
