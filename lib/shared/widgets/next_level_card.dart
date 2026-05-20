import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.82)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warning.withValues(alpha: 0.24),
            AppTheme.warning.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warning.withValues(alpha: 0.20),
            blurRadius: 34,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warning.withValues(alpha: 0.22),
                  blurRadius: 30,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppTheme.warning,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            done ? 'Nivel maximo' : 'Proximo nivel',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFFDDD3B4),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done ? nextLevel : nextLevel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done ? 'Voce chegou no topo.' : 'Faltam $xpToNext XP',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
