import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'premium_card.dart';

class SalesChartCard extends StatelessWidget {
  const SalesChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryValues,
    required this.secondaryValues,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.height = 260,
  });

  final String title;
  final String subtitle;
  final List<double> primaryValues;
  final List<double> secondaryValues;
  final String primaryLabel;
  final String secondaryLabel;
  final double height;

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
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFFB6C2D3)),
                      ),
                    ],
                  ),
                ),
                _Legend(label: primaryLabel, color: AppTheme.primary),
                const SizedBox(width: 10),
                _Legend(label: secondaryLabel, color: AppTheme.secondary),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue * 1.25,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxValue / 3,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
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
                          return Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF7D8798),
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _bar(primaryValues, AppTheme.primary),
                    _bar(secondaryValues, AppTheme.secondary),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.graphite,
                      getTooltipItems: (spots) => [
                        for (final spot in spots)
                          LineTooltipItem(
                            money(spot.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _bar(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.28,
      barWidth: 3,
      isStrokeCapRound: true,
      color: color,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: index == values.length - 1 ? 4 : 2.5,
          color: color,
          strokeWidth: 2,
          strokeColor: AppTheme.surface,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFB6C2D3)),
        ),
      ],
    );
  }
}
