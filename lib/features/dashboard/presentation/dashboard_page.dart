import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/level_card.dart';
import '../../../shared/widgets/progress_metric_card.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(levelUpProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        _Header(level: state.level),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: [
            StatCard(
              title: 'Venda individual hoje',
              value: money(state.dailyIndividualSale),
              subtitle: 'Meta diaria: ${money(state.dailyIndividualGoal)}',
              icon: Icons.person_rounded,
            ),
            StatCard(
              title: 'Venda loja hoje',
              value: money(state.dailyStoreSale),
              subtitle: 'Meta diaria: ${money(state.dailyStoreGoal)}',
              icon: Icons.storefront_rounded,
              color: AppTheme.secondary,
            ),
            StatCard(
              title: 'Comissao estimada',
              value: money(state.estimatedCommission),
              subtitle:
                  'Ind. ${state.individualCommissionRate}% | Loja ${state.storeCommissionRate}%',
              icon: Icons.payments_rounded,
              color: AppTheme.warning,
            ),
            StatCard(
              title: 'Pontos',
              value: '${state.xp} XP',
              subtitle: 'Nivel atual: ${state.level}',
              icon: Icons.bolt_rounded,
              color: AppTheme.danger,
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Progresso',
          child: ResponsiveGrid(
            children: [
              ProgressMetricCard(
                title: 'Mensal individual',
                value: state.monthlyIndividualPercent,
                subtitle: '${money(state.dailyIndividualSale * 22)} projetados',
              ),
              ProgressMetricCard(
                title: 'Semanal individual',
                value: state.weeklyIndividualPercent,
                subtitle: '${money(state.dailyIndividualSale * 5)} projetados',
                color: AppTheme.secondary,
              ),
              ProgressMetricCard(
                title: 'Mensal loja',
                value: state.monthlyStorePercent,
                subtitle: '${money(state.dailyStoreSale * 22)} projetados',
                color: AppTheme.warning,
              ),
              ProgressMetricCard(
                title: 'Semanal loja',
                value: state.weeklyStorePercent,
                subtitle: '${money(state.dailyStoreSale * 5)} projetados',
                color: AppTheme.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LevelCard(
          level: state.level,
          xp: state.xp,
          progress: state.nextLevelProgress,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppConstants.appName,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppConstants.userName} | ${AppConstants.userRole}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB6C2D3)),
        ),
        const SizedBox(height: 14),
        Chip(
          avatar: const Icon(Icons.workspace_premium_rounded, size: 18),
          label: Text('Nivel $level'),
          backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.24)),
        ),
      ],
    );
  }
}
