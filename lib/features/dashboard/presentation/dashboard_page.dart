import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/equipe/application/team_controller.dart';
import '../../../features/equipe/domain/team_challenge.dart';
import '../../../features/equipe/domain/team_state.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(teamProvider);
    final state = asyncState.value ?? TeamState.mock();

    if (asyncState.isLoading && !asyncState.hasValue) {
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
          onRefresh: () => ref.read(teamProvider.notifier).refresh(),
        ),
        _Header(state: state),
        const SizedBox(height: 24),
        AppSection(
          title: 'Resumo geral',
          child: ResponsiveGrid(
            children: [
              StatCard(
                title: 'Venda total loja',
                value: money(state.monthlyStoreSales),
                subtitle: 'Meta mensal ${money(state.monthlyStoreGoal)}',
                icon: Icons.storefront_rounded,
              ),
              StatCard(
                title: 'Venda equipe',
                value: money(state.monthlyTeamSales),
                subtitle: '${state.sellers.length} vendedores ativos',
                icon: Icons.groups_rounded,
                color: AppTheme.secondary,
              ),
              StatCard(
                title: 'Desafios',
                value: money(state.monthlyChallengeTotal),
                subtitle: 'Acumulado no mes',
                icon: Icons.emoji_events_rounded,
                color: AppTheme.warning,
              ),
              StatCard(
                title: 'Comissao estimada',
                value: money(state.estimatedCommissionTotal),
                subtitle: 'Equipe + loja',
                icon: Icons.payments_rounded,
                color: AppTheme.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Ranking de vendas',
          child: _SalesRanking(state: state),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Ranking de desafios',
          child: Column(
            children: [
              _ChallengeRankingBlock(title: 'Geral', state: state),
              const SizedBox(height: 14),
              for (final type in TeamChallengeType.values) ...[
                _ChallengeRankingBlock(
                  title: type.label,
                  state: state,
                  type: type,
                ),
                if (type != TeamChallengeType.values.last)
                  const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: isCompact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              '${AppConstants.userName} - ${AppConstants.userRole}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: isCompact ? TextAlign.center : TextAlign.start,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: isCompact ? Alignment.center : Alignment.centerLeft,
            child: Text(
              AppConstants.storeName,
              maxLines: 1,
              textAlign: TextAlign.center,
              softWrap: false,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFB6C2D3),
                fontSize: isCompact ? 14 : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: isCompact ? WrapAlignment.center : WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                icon: Icons.star_rounded,
                label: 'Melhor vendedor',
                value: state.bestSeller?.seller.name ?? '-',
              ),
              _InfoPill(
                icon: Icons.emoji_events_rounded,
                label: 'Mais desafios',
                value: state.bestChallengeSeller?.sellerName ?? '-',
                color: AppTheme.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppTheme.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width < 430 ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        mainAxisAlignment: MediaQuery.sizeOf(context).width < 430
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: MediaQuery.sizeOf(context).width < 430
                  ? TextAlign.center
                  : TextAlign.start,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesRanking extends StatelessWidget {
  const _SalesRanking({required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    if (state.salesRanking.isEmpty) {
      return const PremiumCard(child: Text('Nenhum vendedor cadastrado.'));
    }

    return Column(
      children: [
        _StoreRankingCard(state: state),
        const SizedBox(height: 14),
        for (var index = 0; index < state.salesRanking.length; index++) ...[
          _SellerRankingCard(
            ranking: state.salesRanking[index],
            position: index + 1,
            highlight: index == 0,
          ),
          if (index != state.salesRanking.length - 1)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StoreRankingCard extends StatelessWidget {
  const _StoreRankingCard({required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: AppTheme.secondary,
      child: _RankingRow(
        position: 0,
        title: 'Venda total da loja',
        value: money(state.monthlyStoreSales),
        subtitle:
            'Semana ${percent(state.weeklyStorePercent)} | Mes ${percent(_ratio(state.monthlyStoreSales, state.monthlyStoreGoal))}',
        color: AppTheme.secondary,
      ),
    );
  }
}

class _SellerRankingCard extends StatelessWidget {
  const _SellerRankingCard({
    required this.ranking,
    required this.position,
    required this.highlight,
  });

  final SellerSalesRanking ranking;
  final int position;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: highlight ? AppTheme.warning : AppTheme.primary,
      child: _RankingRow(
        position: position,
        title: ranking.seller.name,
        value: money(ranking.monthlySales),
        subtitle:
            'Semana ${percent(ranking.weeklyPercent)} | Mes ${percent(ranking.monthlyPercent)}',
        color: highlight ? AppTheme.warning : AppTheme.primary,
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.position,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final int position;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                foregroundColor: color,
                child: Text(position == 0 ? 'L' : '$position'),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB6C2D3)),
              ),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          );
        }

        return Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              foregroundColor: color,
              child: Text(position == 0 ? 'L' : '$position'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB6C2D3)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        );
      },
    );
  }
}

class _ChallengeRankingBlock extends StatelessWidget {
  const _ChallengeRankingBlock({
    required this.title,
    required this.state,
    this.type,
  });

  final String title;
  final TeamState state;
  final TeamChallengeType? type;

  @override
  Widget build(BuildContext context) {
    final ranking = state.challengeRanking(type: type);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;

        return PremiumCard(
          glowColor: AppTheme.warning,
          child: Column(
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
              if (ranking.isEmpty)
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Nenhum desafio no periodo.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (
                  var index = 0;
                  index < ranking.take(5).length;
                  index++
                ) ...[
                  _ChallengeRankingRow(
                    position: index + 1,
                    ranking: ranking[index],
                  ),
                  if (index != ranking.take(5).length - 1)
                    const Divider(height: 18),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _ChallengeRankingRow extends StatelessWidget {
  const _ChallengeRankingRow({required this.position, required this.ranking});

  final int position;
  final ChallengeRanking ranking;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$position. ${ranking.sellerName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${ranking.count}x | ${money(ranking.amount)}',
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return Row(
          children: [
            Text(
              '$position.',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ranking.sellerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('${ranking.count}x'),
            const SizedBox(width: 12),
            Text(
              money(ranking.amount),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        );
      },
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
        LoadingSkeleton(height: 170),
        SizedBox(height: 14),
        LoadingSkeleton(height: 220),
        SizedBox(height: 14),
        LoadingSkeleton(height: 320),
      ],
    );
  }
}

double _ratio(double value, double target) {
  if (target <= 0) return 0;
  return (value / target) * 100;
}
