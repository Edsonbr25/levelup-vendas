import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../shared/widgets/app_section.dart';
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

  @override
  void initState() {
    super.initState();
    final state = ref.read(levelUpProvider);
    _monthlyIndividual = state.monthlyIndividualGoal;
    _weeklyIndividual = state.weeklyIndividualGoal;
    _monthlyStore = state.monthlyStoreGoal;
    _weeklyStore = state.weeklyStoreGoal;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(levelUpProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
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
                    label: 'Meta mensal individual',
                    initialValue: state.monthlyIndividualGoal,
                    onChanged: (value) =>
                        _monthlyIndividual = parseMoney(value),
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    label: 'Meta semanal individual',
                    initialValue: state.weeklyIndividualGoal,
                    onChanged: (value) => _weeklyIndividual = parseMoney(value),
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    label: 'Meta mensal loja',
                    initialValue: state.monthlyStoreGoal,
                    onChanged: (value) => _monthlyStore = parseMoney(value),
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    label: 'Meta semanal loja',
                    initialValue: state.weeklyStoreGoal,
                    onChanged: (value) => _weeklyStore = parseMoney(value),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(levelUpProvider.notifier)
                          .updateGoals(
                            monthlyIndividualGoal: _monthlyIndividual,
                            weeklyIndividualGoal: _weeklyIndividual,
                            monthlyStoreGoal: _monthlyStore,
                            weeklyStoreGoal: _weeklyStore,
                          );
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Salvar metas'),
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
                title: 'Meta diaria individual',
                value: money(state.dailyIndividualGoal),
                subtitle: 'Calculada com base em 22 dias uteis',
                icon: Icons.today_rounded,
              ),
              const SizedBox(height: 14),
              StatCard(
                title: 'Meta diaria loja',
                value: money(state.dailyStoreGoal),
                subtitle: 'Calculada com base em 22 dias uteis',
                icon: Icons.calendar_month_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
