import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/level_card.dart';

class DesafiosPage extends ConsumerStatefulWidget {
  const DesafiosPage({super.key});

  @override
  ConsumerState<DesafiosPage> createState() => _DesafiosPageState();
}

class _DesafiosPageState extends ConsumerState<DesafiosPage> {
  late int _storeGoal;
  late int _pa;
  late int _biggestTicket;

  @override
  void initState() {
    super.initState();
    final state = ref.read(levelUpProvider);
    _storeGoal = state.storeGoalChallenge;
    _pa = state.paChallenge;
    _biggestTicket = state.biggestTicketChallenge;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(levelUpProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        Text(
          'Desafios',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AppSection(
          title: 'Registrar ganhos',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _ChallengeStepper(
                    label: 'Desafio meta loja',
                    value: _storeGoal,
                    color: AppTheme.primary,
                    onChanged: (value) => setState(() => _storeGoal = value),
                  ),
                  const Divider(height: 28),
                  _ChallengeStepper(
                    label: 'Desafio P.A',
                    value: _pa,
                    color: AppTheme.secondary,
                    onChanged: (value) => setState(() => _pa = value),
                  ),
                  const Divider(height: 28),
                  _ChallengeStepper(
                    label: 'Desafio maior boleta',
                    value: _biggestTicket,
                    color: AppTheme.warning,
                    onChanged: (value) =>
                        setState(() => _biggestTicket = value),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(levelUpProvider.notifier)
                          .updateChallenges(
                            storeGoalChallenge: _storeGoal,
                            paChallenge: _pa,
                            biggestTicketChallenge: _biggestTicket,
                          );
                    },
                    icon: const Icon(Icons.emoji_events_rounded),
                    label: const Text('Salvar desafios'),
                  ),
                ],
              ),
            ),
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

class _ChallengeStepper extends StatelessWidget {
  const _ChallengeStepper({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.add_task_rounded, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
          tooltip: 'Diminuir',
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.filled(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Aumentar',
        ),
      ],
    );
  }
}
