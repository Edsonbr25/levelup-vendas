import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'premium_card.dart';

class CircularGoalCard extends StatelessWidget {
  const CircularGoalCard({
    super.key,
    required this.title,
    required this.percentValue,
    required this.amount,
    required this.goal,
    this.color = AppTheme.primary,
  });

  final String title;
  final double percentValue;
  final double amount;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (percentValue / 100).clamp(0, 1).toDouble();

    return PremiumCard(
      glowColor: color,
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Text(
                      percent(percentValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  money(amount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Meta ${money(goal)}',
                  style: const TextStyle(color: Color(0xFFB6C2D3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
