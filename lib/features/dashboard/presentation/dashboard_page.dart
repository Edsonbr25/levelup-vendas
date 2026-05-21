import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/commission_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/gamificacao/application/level_up_controller.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/challenge_summary_card.dart';
import '../../../shared/widgets/circular_goal_card.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/level_badge.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/next_level_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/progress_metric_card.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/sales_chart_card.dart';
import '../../../shared/widgets/streak_card.dart';
import '../../../shared/widgets/xp_progress_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(levelUpProvider);
    final state = asyncState.value ?? LevelUpState.initialMock();
    final isInitialLoading = asyncState.isLoading && !asyncState.hasValue;

    if (isInitialLoading) {
      return const _DashboardSkeleton();
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 430 ? 14 : 18,
        18,
        MediaQuery.sizeOf(context).width < 430 ? 14 : 18,
        96,
      ),
      children: [
        DataStatusBanner(
          state: state,
          isLoading: asyncState.isLoading,
          onRefresh: () => ref.read(levelUpProvider.notifier).refresh(),
        ),
        _HeroHeader(state: state),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: [
            ChallengeSummaryCard(
              title: 'Venda individual hoje',
              value: money(state.dailyIndividualSale),
              subtitle:
                  'Meta diaria semanal: ${money(state.dailyIndividualGoal)}',
              icon: Icons.person_rounded,
            ),
            ChallengeSummaryCard(
              title: 'Venda loja hoje',
              value: money(state.dailyStoreSale),
              subtitle: 'Meta diaria semanal: ${money(state.dailyStoreGoal)}',
              icon: Icons.storefront_rounded,
              color: AppTheme.secondary,
            ),
            StreakCard(streak: state.goalStreak),
          ],
        ),
        const SizedBox(height: 24),
        _CommissionCurrentCard(state: state),
        const SizedBox(height: 24),
        AppSection(
          title: 'Ganhos em desafios',
          child: ResponsiveGrid(
            children: [
              ChallengeSummaryCard(
                title: 'Total do mes',
                value: money(state.monthlyChallengeTotal),
                subtitle: 'Todos os desafios registrados',
                icon: Icons.emoji_events_rounded,
                color: AppTheme.primary,
              ),
              ChallengeSummaryCard(
                title: 'Meta loja',
                value: money(state.monthlyStoreGoalChallengeTotal),
                subtitle: 'Acumulado no mes atual',
                icon: Icons.store_mall_directory_rounded,
                color: AppTheme.secondary,
              ),
              ChallengeSummaryCard(
                title: 'P.A',
                value: money(state.monthlyPaChallengeTotal),
                subtitle: 'Acumulado no mes atual',
                icon: Icons.groups_rounded,
                color: AppTheme.warning,
              ),
              ChallengeSummaryCard(
                title: 'Maior boleta',
                value: money(state.monthlyBiggestTicketChallengeTotal),
                subtitle: 'Acumulado no mes atual',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            final weeklyChart = SalesChartCard(
              title: 'Vendas da semana',
              subtitle: state.weeklyPeriodLabel,
              primaryValues: state.weeklyIndividualChart,
              secondaryValues: state.weeklyStoreChart,
              primaryLabel: 'Eu',
              secondaryLabel: 'Loja',
            );
            final monthlyChart = SalesChartCard(
              title: 'Evolucao mensal',
              subtitle: 'Tendencia por blocos do mes',
              primaryValues: state.monthlyIndividualChart,
              secondaryValues: state.monthlyStoreChart,
              primaryLabel: 'Eu',
              secondaryLabel: 'Loja',
            );

            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: weeklyChart),
                      const SizedBox(width: 14),
                      Expanded(child: monthlyChart),
                    ],
                  )
                : Column(
                    children: [
                      weeklyChart,
                      const SizedBox(height: 14),
                      monthlyChart,
                    ],
                  );
          },
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Progresso',
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final individualGoal = CircularGoalCard(
                    title: 'Meta mensal individual',
                    percentValue: state.monthlyIndividualPercent,
                    amount: state.monthlyIndividualSales,
                    goal: state.monthlyIndividualGoal,
                  );
                  final storeGoal = CircularGoalCard(
                    title: 'Meta mensal loja',
                    percentValue: state.monthlyStorePercent,
                    amount: state.monthlyStoreSales,
                    goal: state.monthlyStoreGoal,
                    color: AppTheme.secondary,
                  );
                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: individualGoal),
                            const SizedBox(width: 14),
                            Expanded(child: storeGoal),
                          ],
                        )
                      : Column(
                          children: [
                            individualGoal,
                            const SizedBox(height: 14),
                            storeGoal,
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              ResponsiveGrid(
                children: [
                  ProgressMetricCard(
                    title: 'Mensal individual',
                    value: state.monthlyIndividualPercent,
                    subtitle:
                        '${money(state.monthlyIndividualSales)} realizados',
                  ),
                  ProgressMetricCard(
                    title: 'Semanal individual',
                    value: state.weeklyIndividualPercent,
                    subtitle:
                        '${money(state.weeklyIndividualSales)} | ${state.weeklyPeriodLabel}',
                    color: AppTheme.secondary,
                  ),
                  ProgressMetricCard(
                    title: 'Mensal loja',
                    value: state.monthlyStorePercent,
                    subtitle: '${money(state.monthlyStoreSales)} realizados',
                    color: AppTheme.warning,
                  ),
                  ProgressMetricCard(
                    title: 'Semanal loja',
                    value: state.weeklyStorePercent,
                    subtitle:
                        '${money(state.weeklyStoreSales)} | ${state.weeklyPeriodLabel}',
                    color: AppTheme.danger,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final xpCard = XpProgressCard(
              xp: state.xp,
              target: state.nextLevelTarget,
              level: state.level,
              nextLevel: state.nextLevel,
              progress: state.nextLevelProgress,
            );
            final nextCard = NextLevelCard(
              nextLevel: state.nextLevel,
              xpToNext: state.xpToNextLevel,
            );
            if (!isWide) {
              return Column(
                children: [
                  xpCard,
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 268,
                    child: nextCard,
                  ),
                ],
              );
            }
            final rowChildren = [
              Expanded(flex: 2, child: xpCard),
              const SizedBox(width: 14),
              Expanded(child: nextCard),
            ];
            return Row(children: rowChildren);
          },
        ),
      ],
    );
  }
}

class _CommissionCurrentCard extends StatelessWidget {
  const _CommissionCurrentCard({required this.state});

  final LevelUpState state;

  @override
  Widget build(BuildContext context) {
    final individual = state.individualCommission;
    final store = state.storeCommission;

    return PremiumCard(
      glowColor: AppTheme.warning,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 430 ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comissao atual',
                    style: TextStyle(
                      color: Color(0xFFB6C2D3),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    money(state.estimatedCommission),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              );
              final message = _CommissionMessage(
                result: _messageResult(individual, store),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), message],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 16),
                  Expanded(child: message),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final individualCard = _CommissionDetailCard(
                title: 'Individual',
                result: individual,
                color: AppTheme.primary,
              );
              final storeCard = _CommissionDetailCard(
                title: 'Loja',
                result: store,
                color: AppTheme.secondary,
              );

              return isWide
                  ? Row(
                      children: [
                        Expanded(child: individualCard),
                        const SizedBox(width: 12),
                        Expanded(child: storeCard),
                      ],
                    )
                  : Column(
                      children: [
                        individualCard,
                        const SizedBox(height: 12),
                        storeCard,
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  CommissionResult _messageResult(
    CommissionResult individual,
    CommissionResult store,
  ) {
    if (!individual.isCommissioning && !store.isCommissioning) {
      return individual.amountToFirstBand <= store.amountToFirstBand
          ? individual
          : store;
    }

    final candidates = [
      individual,
      store,
    ].where((result) => result.hasNextBand).toList();
    if (candidates.isEmpty) {
      return individual.commission >= store.commission ? individual : store;
    }

    candidates.sort((a, b) => a.amountToNextBand.compareTo(b.amountToNextBand));
    return candidates.first;
  }
}

class _CommissionMessage extends StatelessWidget {
  const _CommissionMessage({required this.result});

  final CommissionResult result;

  @override
  Widget build(BuildContext context) {
    final text = !result.isCommissioning
        ? 'Faltam ${money(result.amountToFirstBand)} para começar a comissionar'
        : result.hasNextBand
        ? 'Faltam ${money(result.amountToNextBand)} para proxima faixa'
        : 'Voce ja esta comissionando nesta faixa';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppTheme.warning,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CommissionDetailCard extends StatelessWidget {
  const _CommissionDetailCard({
    required this.title,
    required this.result,
    required this.color,
  });

  final String title;
  final CommissionResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB6C2D3),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RateBadge(rate: result.appliedRate, color: color),
            ],
          ),
          const SizedBox(height: 10),
          _CommissionLine(label: 'Venda no mes', value: money(result.sales)),
          const SizedBox(height: 6),
          _CommissionLine(
            label: 'Meta atingida',
            value: percent(result.percentReached),
          ),
          const SizedBox(height: 6),
          _CommissionLine(
            label: 'Comissao',
            value: money(result.commission),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _CommissionLine extends StatelessWidget {
  const _CommissionLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFB6C2D3)),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RateBadge extends StatelessWidget {
  const _RateBadge({required this.rate, required this.color});

  final double rate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        formatRate(rate),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.state});

  final LevelUpState state;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 430 ? 18 : 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 390;
          return Column(
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
                          AppConstants.appName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                                fontSize: isCompact ? 34 : null,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Edson | Coordenador',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFFB6C2D3),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'I Like Mobis - P 15 WALLIG',
                              maxLines: 1,
                              softWrap: false,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFFB6C2D3),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  LevelBadge(level: state.level),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, pillConstraints) {
                  final widePill = _HeroPill(
                    icon: Icons.payments_rounded,
                    label: 'Comissao',
                    value: money(state.estimatedCommission),
                    color: AppTheme.warning,
                    fullWidth: true,
                  );
                  final xpPill = _HeroPill(
                    icon: Icons.bolt_rounded,
                    label: 'XP',
                    value: '${state.xp}',
                    color: AppTheme.primary,
                  );
                  final streakPill = _HeroPill(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '${state.goalStreak}',
                    color: AppTheme.danger,
                  );
                  if (pillConstraints.maxWidth < 430) {
                    return Column(
                      children: [
                        widePill,
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: xpPill),
                            const SizedBox(width: 12),
                            Expanded(child: streakPill),
                          ],
                        ),
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [widePill, xpPill, streakPill],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            if (fullWidth) const Spacer(),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(color: Color(0xFFB6C2D3)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: const [
        LoadingSkeleton(height: 168),
        SizedBox(height: 18),
        LoadingSkeleton(height: 172),
        SizedBox(height: 14),
        LoadingSkeleton(height: 260),
        SizedBox(height: 14),
        LoadingSkeleton(height: 260),
        SizedBox(height: 14),
        LoadingSkeleton(height: 180),
      ],
    );
  }
}
