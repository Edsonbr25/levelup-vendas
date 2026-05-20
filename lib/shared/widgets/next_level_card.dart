import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'premium_card.dart';

class NextLevelCard extends StatelessWidget {
  const NextLevelCard({
    super.key,
    required this.nextLevel,
    required this.xpToNext,
  });

  final String nextLevel;
  final int xpToNext;

  @override
  Widget build(BuildContext context) {
    final done = xpToNext == 0;

    return PremiumCard(
      glowColor: AppTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            done ? 'Nivel maximo' : 'Proximo nivel',
            style: const TextStyle(color: Color(0xFFB6C2D3)),
          ),
          const SizedBox(height: 6),
          Text(
            done ? nextLevel : nextLevel,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            done ? 'Voce chegou no topo.' : 'Faltam $xpToNext XP',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
