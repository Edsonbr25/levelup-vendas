import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/commission_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/equipe/application/team_controller.dart';
import '../../../features/equipe/domain/seller.dart';
import '../../../features/equipe/domain/team_goal.dart';
import '../../../features/equipe/domain/team_state.dart';
import '../../../shared/widgets/animated_action_button.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_card.dart';

class MetasPage extends ConsumerStatefulWidget {
  const MetasPage({super.key});

  @override
  ConsumerState<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends ConsumerState<MetasPage> {
  final _sellerNameController = TextEditingController();
  final _sellerRoleController = TextEditingController();
  final _monthlyGoalController = TextEditingController();
  final _weeklyGoalController = TextEditingController();
  GoalOwnerType _ownerType = GoalOwnerType.store;
  Seller? _seller;
  DateTime _weekStart = _defaultWeekStart();
  DateTime _weekEnd = _defaultWeekStart().add(const Duration(days: 6));

  @override
  void dispose() {
    _sellerNameController.dispose();
    _sellerRoleController.dispose();
    _monthlyGoalController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(teamProvider);
    final state = asyncState.value ?? TeamState.mock();
    _seller ??= state.sellers.isEmpty ? null : state.sellers.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        DataStatusBanner(
          state: state,
          isLoading: asyncState.isLoading,
          onRefresh: () => ref.read(teamProvider.notifier).refresh(),
        ),
        Text(
          'Metas',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AppSection(
          title: 'Equipe',
          child: PremiumCard(
            child: Column(
              children: [
                TextField(
                  controller: _sellerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do vendedor',
                    prefixIcon: Icon(Icons.person_add_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sellerRoleController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo opcional',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedActionButton(
                  onPressed: asyncState.isLoading ? null : _createSeller,
                  icon: Icons.save_rounded,
                  label: 'Salvar vendedor',
                  expand: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Cadastrar metas',
          child: PremiumCard(
            child: Column(
              children: [
                SegmentedButton<GoalOwnerType>(
                  segments: const [
                    ButtonSegment(
                      value: GoalOwnerType.store,
                      label: Text('Loja'),
                      icon: Icon(Icons.storefront_rounded),
                    ),
                    ButtonSegment(
                      value: GoalOwnerType.seller,
                      label: Text('Vendedor'),
                      icon: Icon(Icons.person_rounded),
                    ),
                  ],
                  selected: {_ownerType},
                  onSelectionChanged: (value) {
                    setState(() => _ownerType = value.first);
                  },
                ),
                if (_ownerType == GoalOwnerType.seller) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Seller>(
                    initialValue: state.sellers.contains(_seller)
                        ? _seller
                        : null,
                    decoration: const InputDecoration(labelText: 'Vendedor'),
                    items: [
                      for (final seller in state.sellers)
                        DropdownMenuItem(
                          value: seller,
                          child: Text(seller.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _seller = value),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _monthlyGoalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Meta mensal',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weeklyGoalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Meta semanal',
                    prefixIcon: Icon(Icons.date_range_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final start = _DateTile(
                      label: 'Inicio da semana',
                      date: _weekStart,
                      onTap: () => _pickDate(isStart: true),
                    );
                    final end = _DateTile(
                      label: 'Fim da semana',
                      date: _weekEnd,
                      onTap: () => _pickDate(isStart: false),
                    );
                    return constraints.maxWidth >= 620
                        ? Row(
                            children: [
                              Expanded(child: start),
                              const SizedBox(width: 12),
                              Expanded(child: end),
                            ],
                          )
                        : Column(
                            children: [start, const SizedBox(height: 12), end],
                          );
                  },
                ),
                const SizedBox(height: 18),
                AnimatedActionButton(
                  onPressed: asyncState.isLoading ? null : _saveGoals,
                  icon: Icons.flag_rounded,
                  label: 'Salvar metas',
                  expand: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Metas automaticas',
          child: Column(
            children: [
              _AutomaticTargets(
                title: 'Loja',
                goal: state.monthlyStoreGoal,
                bands: CommissionCalculator.storeBands,
                color: AppTheme.secondary,
              ),
              const SizedBox(height: 14),
              for (final ranking in state.salesRanking) ...[
                _AutomaticTargets(
                  title: ranking.seller.name,
                  goal: ranking.monthlyGoal,
                  bands: CommissionCalculator.individualBands,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        AppSection(
          title: 'Resultado semanal',
          child: ResponsiveGrid(
            children: [
              StatCard(
                title: 'Loja',
                value: percent(state.weeklyStorePercent),
                subtitle:
                    '${money(state.weeklyStoreSales)} de ${money(state.weeklyStoreGoal)} | ${_status(state.weeklyStorePercent)}',
                icon: Icons.storefront_rounded,
                color: AppTheme.secondary,
              ),
              for (final ranking in state.salesRanking)
                StatCard(
                  title: ranking.seller.name,
                  value: percent(ranking.weeklyPercent),
                  subtitle:
                      '${money(ranking.weeklySales)} de ${money(ranking.weeklyGoal)} | ${_status(ranking.weeklyPercent)}',
                  icon: Icons.person_rounded,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createSeller() async {
    final name = _sellerNameController.text.trim();
    if (name.isEmpty) return;
    await ref
        .read(teamProvider.notifier)
        .createSeller(Seller(name: name, role: _sellerRoleController.text));
    _sellerNameController.clear();
    _sellerRoleController.clear();
  }

  Future<void> _saveGoals() async {
    if (_weekEnd.isBefore(_weekStart)) return;
    if (_ownerType == GoalOwnerType.seller && _seller == null) return;
    final sellerId = _ownerType == GoalOwnerType.seller ? _seller?.id : null;
    final sellerName = _ownerType == GoalOwnerType.seller
        ? _seller?.name
        : null;
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month);
    final monthEnd = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
    ).subtract(const Duration(days: 1));
    final notifier = ref.read(teamProvider.notifier);
    final monthly = parseMoney(_monthlyGoalController.text);
    final weekly = parseMoney(_weeklyGoalController.text);
    if (monthly > 0) {
      await notifier.saveGoal(
        TeamGoal(
          ownerType: _ownerType,
          sellerId: sellerId,
          sellerName: sellerName,
          periodType: GoalPeriodType.monthly,
          periodStart: monthStart,
          periodEnd: monthEnd,
          amount: monthly,
        ),
      );
    }
    if (weekly > 0) {
      await notifier.saveGoal(
        TeamGoal(
          ownerType: _ownerType,
          sellerId: sellerId,
          sellerName: sellerName,
          periodType: GoalPeriodType.weekly,
          periodStart: _weekStart,
          periodEnd: _weekEnd,
          amount: weekly,
        ),
      );
    }
    _monthlyGoalController.clear();
    _weeklyGoalController.clear();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _weekStart : _weekEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _weekStart = selected;
      } else {
        _weekEnd = selected;
      }
    });
  }
}

class _AutomaticTargets extends StatelessWidget {
  const _AutomaticTargets({
    required this.title,
    required this.goal,
    required this.bands,
    required this.color,
  });

  final String title;
  final double goal;
  final List<CommissionBand> bands;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final targets = CommissionCalculator.monthlyTargets(
      goal: goal,
      days: CommissionCalculator.daysInMonth(),
      bands: bands,
    );
    return PremiumCard(
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final cards = [
                for (final target in targets)
                  _TargetChip(target: target, color: color),
              ];
              return compact
                  ? Column(
                      children: [
                        for (final card in cards) ...[
                          card,
                          if (card != cards.last) const SizedBox(height: 8),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        for (final card in cards) ...[
                          Expanded(child: card),
                          if (card != cards.last) const SizedBox(width: 8),
                        ],
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.target, required this.color});

  final GoalRangeTarget target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${target.percent.toStringAsFixed(0)}% | ${formatRate(target.commissionRate)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(money(target.total), overflow: TextOverflow.ellipsis),
          Text(
            '${money(target.daily)} por dia',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFB6C2D3)),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('$label: ${_dateLabel(date)}'),
        ),
      ),
    );
  }
}

String _status(double percentValue) {
  if (percentValue >= 120) return 'superou a meta';
  if (percentValue >= 100) return 'meta atingida';
  return 'abaixo da meta';
}

DateTime _defaultWeekStart() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
