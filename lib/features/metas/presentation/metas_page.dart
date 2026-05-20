import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                        _monthlyIndividual = parseMoney(value),
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
                    onChanged: (value) => _monthlyStore = parseMoney(value),
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
              StatCard(
                title: 'Meta diaria semanal individual',
                value: money(state.dailyIndividualGoal),
                subtitle:
                    '${state.weeklyPeriodLabel} | ${state.weeklyPeriodDays} dias',
                icon: Icons.today_rounded,
              ),
              const SizedBox(height: 14),
              StatCard(
                title: 'Meta diaria semanal loja',
                value: money(state.dailyStoreGoal),
                subtitle:
                    '${state.weeklyPeriodLabel} | ${state.weeklyPeriodDays} dias',
                icon: Icons.calendar_month_rounded,
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
