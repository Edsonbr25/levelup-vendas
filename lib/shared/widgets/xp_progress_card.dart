import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'premium_card.dart';

class XpProgressCard extends StatelessWidget {
  const XpProgressCard({
    super.key,
    required this.xp,
    required this.target,
    required this.level,
    required this.nextLevel,
    required this.progress,
  });

  final int xp;
  final int target;
  final String level;
  final String nextLevel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: AppTheme.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppTheme.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'XP de performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$xp / $target',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 14,
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.warning),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            '$level agora. Proximo nivel: $nextLevel',
            style: const TextStyle(color: Color(0xFFB6C2D3)),
          ),
        ],
      ),
    );
  }
}
