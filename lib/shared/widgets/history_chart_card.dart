import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'premium_card.dart';

class HistoryChartCard extends StatelessWidget {
  const HistoryChartCard({
    super.key,
    required this.title,
    required this.primaryValues,
    required this.secondaryValues,
  });

  final String title;
  final List<double> primaryValues;
  final List<double> secondaryValues;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      ...primaryValues,
      ...secondaryValues,
      1.0,
    ].reduce((value, item) => value > item ? value : item);

    return PremiumCard(
      glowColor: AppTheme.secondary,
      child: SizedBox(
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.2,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxValue / 3,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= primaryValues.length) {
                            return const SizedBox.shrink();
                          }
                          final day = index + 1;
                          return Text(
                            day % 5 == 0 || day == 1 ? '$day' : '',
                            style: const TextStyle(
                              color: Color(0xFF7D8798),
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < primaryValues.length; index++)
                      BarChartGroupData(
                        x: index,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: primaryValues[index],
                            color: AppTheme.primary,
                            width: 4,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          BarChartRodData(
                            toY: secondaryValues[index],
                            color: AppTheme.secondary,
                            width: 4,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ],
                      ),
                  ],
                  barTouchData: BarTouchData(enabled: true),
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                _Legend(label: 'Individual', color: AppTheme.primary),
                SizedBox(width: 14),
                _Legend(label: 'Loja', color: AppTheme.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFFB6C2D3))),
      ],
    );
  }
}
