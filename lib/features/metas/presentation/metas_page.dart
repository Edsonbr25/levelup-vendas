import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/commission_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/gamificacao/application/level_up_controller.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../shared/widgets/animated_action_button.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/money_field.dart';
import '../../../shared/widgets/stat_card.dart';

class MetasPage extends ConsumerStatefulWidget {
  const MetasPage({super.key});

  @override
  ConsumerState<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends ConsumerState<MetasPage> {
  late double _monthlyIndividual;
  late double _weeklyIndividual;
  late double _monthlyStore;
  late double _weeklyStore;
  late DateTime _weeklyStartDate;
  late DateTime _weeklyEndDate;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final state = ref.read(levelUpProvider).value ?? LevelUpState.initialMock();
    _monthlyIndividual = state.monthlyIndividualGoal;
    _weeklyIndividual = state.weeklyIndividualGoal;
    _monthlyStore = state.monthlyStoreGoal;
    _weeklyStore = state.weeklyStoreGoal;
    _weeklyStartDate = state.weeklyStartDate;
    _weeklyEndDate = state.weeklyEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(levelUpProvider);
    final state = asyncState.value ?? LevelUpState.initialMock();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        DataStatusBanner(
          state: state,
          isLoading: asyncState.isLoading,
          onRefresh: () => ref.read(levelUpProvider.notifier).refresh(),
        ),
        Text(
          'Metas',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AppSection(
          title: 'Cadastrar metas',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  MoneyField(
                    key: ValueKey(
                      'monthly-individual-${state.monthlyIndividualGoal}',
                    ),
                    label: 'Meta mensal individual',
                    initialValue: state.monthlyIndividualGoal,
                    onChanged: (value) =>
                        setState(() => _monthlyIndividual = parseMoney(value)),
                  ),
                  const SizedBox(height: 12),
                  _GoalRangePreview(
                    title: 'Faixas da meta individual',
                    goal: _monthlyIndividual,
                    ranges: const [
                      _GoalRange(percentValue: 90, commission: '3%'),
                      _GoalRange(percentValue: 100, commission: '5%'),
                      _GoalRange(percentValue: 120, commission: '6%'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    key: ValueKey(
                      'weekly-individual-${state.weeklyIndividualGoal}',
                    ),
                    label: 'Meta semanal individual',
                    initialValue: state.weeklyIndividualGoal,
                    onChanged: (value) => _weeklyIndividual = parseMoney(value),
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    key: ValueKey('monthly-store-${state.monthlyStoreGoal}'),
                    label: 'Meta mensal loja',
                    initialValue: state.monthlyStoreGoal,
                    onChanged: (value) =>
                        setState(() => _monthlyStore = parseMoney(value)),
                  ),
                  const SizedBox(height: 12),
                  _GoalRangePreview(
                    title: 'Faixas da meta loja',
                    goal: _monthlyStore,
                    ranges: const [
                      _GoalRange(percentValue: 95, commission: '0,5%'),
                      _GoalRange(percentValue: 100, commission: '2%'),
                      _GoalRange(percentValue: 120, commission: '3%'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    key: ValueKey('weekly-store-${state.weeklyStoreGoal}'),
                    label: 'Meta semanal loja',
                    initialValue: state.weeklyStoreGoal,
                    onChanged: (value) => _weeklyStore = parseMoney(value),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 620;
                      final start = _WeekDateField(
                        label: 'Inicio da semana',
                        date: _weeklyStartDate,
                        onTap: () => _pickWeeklyDate(isStart: true),
                      );
                      final end = _WeekDateField(
                        label: 'Fim da semana',
                        date: _weeklyEndDate,
                        onTap: () => _pickWeeklyDate(isStart: false),
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: start),
                            const SizedBox(width: 12),
                            Expanded(child: end),
                          ],
                        );
                      }

                      return Column(
                        children: [start, const SizedBox(height: 12), end],
                      );
                    },
                  ),
                  if (_validationMessage != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _validationMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  AnimatedActionButton(
                    onPressed: asyncState.isLoading ? null : _saveGoals,
                    icon: Icons.save_rounded,
                    label: 'Salvar metas',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Metas automaticas',
          child: Column(
            children: [
              _AutomaticMonthlyTargets(
                title: 'Individual',
                goal: state.monthlyIndividualGoal,
                bands: CommissionCalculator.individualBands,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 14),
              _AutomaticMonthlyTargets(
                title: 'Loja',
                goal: state.monthlyStoreGoal,
                bands: CommissionCalculator.storeBands,
                color: AppTheme.secondary,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 680;
                  final individual = StatCard(
                    title: 'Meta diaria semanal individual',
                    value: money(state.dailyIndividualGoal),
                    subtitle:
                        '${state.weeklyPeriodLabel} | ${state.weeklyPeriodDays} dias',
                    icon: Icons.today_rounded,
                  );
                  final store = StatCard(
                    title: 'Meta diaria semanal loja',
                    value: money(state.dailyStoreGoal),
                    subtitle:
                        '${state.weeklyPeriodLabel} | ${state.weeklyPeriodDays} dias',
                    icon: Icons.calendar_month_rounded,
                    color: AppTheme.warning,
                  );

                  return isWide
                      ? Row(
                          children: [
                            Expanded(child: individual),
                            const SizedBox(width: 14),
                            Expanded(child: store),
                          ],
                        )
                      : Column(
                          children: [
                            individual,
                            const SizedBox(height: 14),
                            store,
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickWeeklyDate({required bool isStart}) async {
    final initialDate = isStart ? _weeklyStartDate : _weeklyEndDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _weeklyStartDate = selected;
      } else {
        _weeklyEndDate = selected;
      }
      _validationMessage = null;
    });
  }

  Future<void> _saveGoals() async {
    final start = DateTime(
      _weeklyStartDate.year,
      _weeklyStartDate.month,
      _weeklyStartDate.day,
    );
    final end = DateTime(
      _weeklyEndDate.year,
      _weeklyEndDate.month,
      _weeklyEndDate.day,
    );

    if (end.isBefore(start)) {
      setState(() {
        _validationMessage =
            'A data final da semana nao pode ser menor que a data inicial.';
      });
      return;
    }

    await ref
        .read(levelUpProvider.notifier)
        .updateGoals(
          monthlyIndividualGoal: _monthlyIndividual,
          weeklyIndividualGoal: _weeklyIndividual,
          monthlyStoreGoal: _monthlyStore,
          weeklyStoreGoal: _weeklyStore,
          weeklyStartDate: start,
          weeklyEndDate: end,
        );
  }
}

class _AutomaticMonthlyTargets extends StatelessWidget {
  const _AutomaticMonthlyTargets({
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
    final days = CommissionCalculator.daysInMonth();
    final targets = CommissionCalculator.monthlyTargets(
      goal: goal,
      days: days,
      bands: bands,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$days dias',
                style: const TextStyle(
                  color: Color(0xFFB6C2D3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 620;
              final cards = [
                for (final target in targets)
                  _AutomaticTargetCard(target: target, color: color),
              ];

              if (isCompact) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (final card in cards) ...[
                    Expanded(child: card),
                    if (card != cards.last) const SizedBox(width: 10),
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

class _AutomaticTargetCard extends StatelessWidget {
  const _AutomaticTargetCard({required this.target, required this.color});

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
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PercentBadge(
                label: '${target.percent.toStringAsFixed(0)}%',
                color: color,
              ),
              _PercentBadge(
                label: 'comissao ${formatRate(target.commissionRate)}',
                color: AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            money(target.total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${money(target.daily)} por dia',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB6C2D3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GoalRangePreview extends StatelessWidget {
  const _GoalRangePreview({
    required this.title,
    required this.goal,
    required this.ranges,
  });

  final String title;
  final double goal;
  final List<_GoalRange> ranges;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final cards = [
          for (final range in ranges)
            _GoalRangeChip(goal: goal, range: range, compact: isCompact),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceAlt.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB6C2D3),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (isCompact)
                Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 8),
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    for (final card in cards) ...[
                      Expanded(child: card),
                      if (card != cards.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalRangeChip extends StatelessWidget {
  const _GoalRangeChip({
    required this.goal,
    required this.range,
    required this.compact,
  });

  final double goal;
  final _GoalRange range;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final amount = goal * (range.percentValue / 100);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 11 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
      ),
      child: compact
          ? Row(
              children: [
                _RangePercentLabel(range: range),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    money(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RangePercentLabel(range: range),
                const SizedBox(height: 6),
                Text(
                  money(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
    );
  }
}

class _RangePercentLabel extends StatelessWidget {
  const _RangePercentLabel({required this.range});

  final _GoalRange range;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${range.percentValue.toStringAsFixed(0)}% | comissao ${range.commission}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFB6C2D3),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GoalRange {
  const _GoalRange({required this.percentValue, required this.commission});

  final double percentValue;
  final String commission;
}

class _WeekDateField extends StatelessWidget {
  const _WeekDateField({
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, color: Color(0xFFB6C2D3)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB6C2D3),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLabel(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
