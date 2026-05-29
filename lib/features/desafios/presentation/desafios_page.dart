import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/desafios/domain/challenge_entry.dart';
import '../../../features/gamificacao/application/level_up_controller.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../shared/widgets/animated_action_button.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_card.dart';

class DesafiosPage extends ConsumerStatefulWidget {
  const DesafiosPage({super.key});

  @override
  ConsumerState<DesafiosPage> createState() => _DesafiosPageState();
}

class _DesafiosPageState extends ConsumerState<DesafiosPage> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  ChallengeType _type = ChallengeType.storeGoal;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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
          'Desafios',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AppSection(
          title: 'Cadastrar desafio ganho',
          child: PremiumCard(
            child: Column(
              children: [
                DropdownButtonFormField<ChallengeType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo do desafio',
                    prefixIcon: Icon(Icons.emoji_events_rounded),
                  ),
                  items: [
                    for (final type in ChallengeType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor ganho',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observacao opcional',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                _DatePickerTile(date: _date, onTap: _pickDate),
                const SizedBox(height: 18),
                AnimatedActionButton(
                  onPressed: asyncState.isLoading ? null : _saveChallenge,
                  icon: Icons.save_rounded,
                  label: 'Salvar desafio',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Acumulado mensal',
          child: ResponsiveGrid(
            children: [
              StatCard(
                title: 'Total do mes',
                value: money(state.monthlyChallengeTotal),
                subtitle: 'Historico mensal de desafios',
                icon: Icons.payments_rounded,
              ),
              StatCard(
                title: 'Meta loja',
                value: money(state.monthlyStoreGoalChallengeTotal),
                subtitle: 'Acumulado mensal',
                icon: Icons.storefront_rounded,
                color: AppTheme.secondary,
              ),
              StatCard(
                title: 'P.A',
                value: money(state.monthlyPaChallengeTotal),
                subtitle: 'Acumulado mensal',
                icon: Icons.groups_rounded,
                color: AppTheme.warning,
              ),
              StatCard(
                title: 'Maior boleta',
                value: money(state.monthlyBiggestTicketChallengeTotal),
                subtitle: 'Acumulado mensal',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Acumulado geral por desafio',
          child: ResponsiveGrid(
            children: [
              _ChallengeTotalCard(
                type: ChallengeType.storeGoal,
                monthly: state.monthlyStoreGoalChallengeTotal,
                total: state.storeGoalChallengeTotal,
                count: state.storeGoalChallengeCount,
                color: AppTheme.secondary,
              ),
              _ChallengeTotalCard(
                type: ChallengeType.pa,
                monthly: state.monthlyPaChallengeTotal,
                total: state.paChallengeTotal,
                count: state.paChallengeCount,
                color: AppTheme.warning,
              ),
              _ChallengeTotalCard(
                type: ChallengeType.biggestTicket,
                monthly: state.monthlyBiggestTicketChallengeTotal,
                total: state.biggestTicketChallengeTotal,
                count: state.biggestTicketChallengeCount,
                color: AppTheme.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Historico mensal',
          child: _MonthlyHistory(state: state),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Desafios cadastrados',
          child: _ChallengeHistory(
            entries: state.challenges,
            isLoading: asyncState.isLoading,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _saveChallenge() async {
    final amount = parseMoney(_amountController.text);
    if (amount <= 0) return;
    final previousXp =
        ref.read(levelUpProvider).value?.xp ?? LevelUpState.initialMock().xp;
    final challengeType = _type;

    await ref
        .read(levelUpProvider.notifier)
        .addChallenge(
          type: _type,
          amount: amount,
          date: _date,
          notes: _notesController.text,
        );

    final currentXp = ref.read(levelUpProvider).value?.xp ?? previousXp;
    final gainedXp = (currentXp - previousXp)
        .clamp(_challengeXp(challengeType), 999)
        .toInt();
    if (mounted) {
      _showXpGainAnimation(gainedXp, challengeType.label);
    }

    _amountController.clear();
    _notesController.clear();
  }

  int _challengeXp(ChallengeType type) {
    return switch (type) {
      ChallengeType.storeGoal => 50,
      ChallengeType.pa => 25,
      ChallengeType.biggestTicket => 40,
    };
  }

  void _showXpGainAnimation(int xp, String label) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _XpGainOverlay(
        xp: xp,
        label: label,
        onCompleted: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _XpGainOverlay extends StatefulWidget {
  const _XpGainOverlay({
    required this.xp,
    required this.label,
    required this.onCompleted,
  });

  final int xp;
  final String label;
  final VoidCallback onCompleted;

  @override
  State<_XpGainOverlay> createState() => _XpGainOverlayState();
}

class _XpGainOverlayState extends State<_XpGainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.82,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 30),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Offset.zero,
          end: const Offset(0, -0.1),
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, topPadding > 0 ? 12 : 18, 18, 0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacity.value,
                    child: SlideTransition(
                      position: _slide,
                      child: Transform.scale(scale: _scale.value, child: child),
                    ),
                  );
                },
                child: _XpGainCardShell(xp: widget.xp, label: widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _XpGainCardShell extends StatelessWidget {
  const _XpGainCardShell({required this.xp, required this.label});

  final int xp;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.22),
            blurRadius: 34,
            spreadRadius: -10,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppTheme.warning.withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: -12,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.16),
            AppTheme.surface,
            AppTheme.warning.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppTheme.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+$xp XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Desafio $label concluido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB6C2D3),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.emoji_events_rounded, color: AppTheme.warning),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.event_rounded, color: Color(0xFFB6C2D3)),
              const SizedBox(width: 12),
              Expanded(child: Text('Data: ${_dateLabel(date)}')),
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

class _ChallengeTotalCard extends StatelessWidget {
  const _ChallengeTotalCard({
    required this.type,
    required this.monthly,
    required this.total,
    required this.count,
    required this.color,
  });

  final ChallengeType type;
  final double monthly;
  final double total;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.emoji_events_rounded, color: color),
          const SizedBox(height: 16),
          Text(type.label, style: const TextStyle(color: Color(0xFFB6C2D3))),
          const SizedBox(height: 6),
          Text(
            money(total),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('${money(monthly)} no mes | $count registros'),
        ],
      ),
    );
  }
}

class _MonthlyHistory extends StatelessWidget {
  const _MonthlyHistory({required this.state});

  final LevelUpState state;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          _HistoryRow(
            label: 'Total mensal',
            value: state.monthlyChallengeTotal,
          ),
          const Divider(height: 24),
          _HistoryRow(
            label: ChallengeType.storeGoal.label,
            value: state.monthlyStoreGoalChallengeTotal,
          ),
          _HistoryRow(
            label: ChallengeType.pa.label,
            value: state.monthlyPaChallengeTotal,
          ),
          _HistoryRow(
            label: ChallengeType.biggestTicket.label,
            value: state.monthlyBiggestTicketChallengeTotal,
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            money(value),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ChallengeHistory extends ConsumerWidget {
  const _ChallengeHistory({required this.entries, required this.isLoading});

  final List<ChallengeEntry> entries;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const PremiumCard(child: Text('Nenhum desafio cadastrado ainda.'));
    }

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final entry in entries.take(30)) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.primary,
                ),
              ),
              title: Text(entry.typeLabel),
              subtitle: Text(
                '${_dateLabel(entry.date)}${entry.notes == null || entry.notes!.isEmpty ? '' : ' | ${entry.notes}'}',
              ),
              onTap: entry.id == null || isLoading
                  ? null
                  : () => _showEditSheet(context, ref, entry),
              onLongPress: entry.id == null || isLoading
                  ? null
                  : () => _confirmDelete(context, ref, entry),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              titleAlignment: ListTileTitleAlignment.center,
              dense: false,
              enabled: !isLoading,
              leadingAndTrailingTextStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
              minVerticalPadding: 10,
              horizontalTitleGap: 12,
              isThreeLine: entry.notes != null && entry.notes!.isNotEmpty,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    money(entry.amount),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  PopupMenuButton<_ChallengeAction>(
                    enabled: entry.id != null && !isLoading,
                    tooltip: 'Acoes',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) {
                      switch (action) {
                        case _ChallengeAction.edit:
                          _showEditSheet(context, ref, entry);
                        case _ChallengeAction.delete:
                          _confirmDelete(context, ref, entry);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ChallengeAction.edit,
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: _ChallengeAction.delete,
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (entry != entries.take(30).last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    ChallengeEntry entry,
  ) async {
    final updated = await showModalBottomSheet<ChallengeEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _EditChallengeSheet(entry: entry),
    );

    if (updated != null) {
      await ref.read(levelUpProvider.notifier).updateChallenge(updated);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ChallengeEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir desafio?'),
        content: Text(
          'Esta acao removera o desafio ${entry.typeLabel} de ${money(entry.amount)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(levelUpProvider.notifier).deleteChallenge(entry);
    }
  }
}

enum _ChallengeAction { edit, delete }

class _EditChallengeSheet extends StatefulWidget {
  const _EditChallengeSheet({required this.entry});

  final ChallengeEntry entry;

  @override
  State<_EditChallengeSheet> createState() => _EditChallengeSheetState();
}

class _EditChallengeSheetState extends State<_EditChallengeSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late ChallengeType _type;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _type = widget.entry.type;
    _date = widget.entry.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editar desafio',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ChallengeType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Tipo do desafio',
              prefixIcon: Icon(Icons.emoji_events_rounded),
            ),
            items: [
              for (final type in ChallengeType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _type = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor ganho',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observacao opcional',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 12),
          _DatePickerTile(date: _date, onTap: _pickDate),
          const SizedBox(height: 18),
          AnimatedActionButton(
            onPressed: _save,
            icon: Icons.save_rounded,
            label: 'Salvar alteracoes',
            expand: true,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  void _save() {
    final amount = parseMoney(_amountController.text);
    if (amount <= 0) return;

    Navigator.of(context).pop(
      widget.entry.copyWith(
        date: _date,
        type: _type,
        amount: amount,
        notes: _notesController.text,
      ),
    );
  }
}
