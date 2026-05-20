import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'premium_card.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: AppTheme.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppTheme.danger,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Streak de metas',
            style: TextStyle(color: Color(0xFFB6C2D3)),
          ),
          const SizedBox(height: 6),
          Text(
            '$streak combos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            streak == 0
                ? 'Ainda da para virar o dia.'
                : 'Sequencia ativa hoje.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
