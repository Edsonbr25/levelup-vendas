import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/equipe/application/team_controller.dart';
import '../../../features/equipe/domain/seller.dart';
import '../../../features/equipe/domain/team_challenge.dart';
import '../../../features/equipe/domain/team_state.dart';
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
  DateTime _date = DateTime.now();
  TeamChallengeType _type = TeamChallengeType.storeGoal;
  Seller? _seller;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
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
          'Desafios',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AppSection(
          title: 'Registrar desafio entregue',
          child: PremiumCard(
            child: Column(
              children: [
                DropdownButtonFormField<Seller>(
                  initialValue: state.sellers.contains(_seller)
                      ? _seller
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Vendedor/responsavel',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  items: [
                    for (final seller in state.sellers)
                      DropdownMenuItem(value: seller, child: Text(seller.name)),
                  ],
                  onChanged: (value) => setState(() => _seller = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TeamChallengeType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo do desafio',
                    prefixIcon: Icon(Icons.emoji_events_rounded),
                  ),
                  items: [
                    for (final type in TeamChallengeType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 12),
                TextField(
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
                TextField(
                  controller: _notesController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observacao opcional',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                _DateTile(date: _date, onTap: _pickDate),
                const SizedBox(height: 18),
                AnimatedActionButton(
                  onPressed: asyncState.isLoading ? null : _createChallenge,
                  icon: Icons.save_rounded,
                  label: 'Salvar desafio',
                  expand: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Resumo do mes',
          child: ResponsiveGrid(
            children: [
              StatCard(
                title: 'Total em desafios',
                value: money(state.monthlyChallengeTotal),
                icon: Icons.payments_rounded,
              ),
              for (final type in TeamChallengeType.values)
                StatCard(
                  title: type.label,
                  value: money(
                    state.monthChallenges
                        .where((entry) => entry.type == type)
                        .fold(0, (total, entry) => total + entry.amount),
                  ),
                  icon: Icons.emoji_events_rounded,
                  color: _typeColor(type),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Rankings por categoria',
          child: Column(
            children: [
              for (final type in TeamChallengeType.values) ...[
                _RankingCard(title: type.label, state: state, type: type),
                if (type != TeamChallengeType.values.last)
                  const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Registros do mes',
          child: _ChallengeList(state: state, isLoading: asyncState.isLoading),
        ),
      ],
    );
  }

  Future<void> _createChallenge() async {
    final amount = parseMoney(_amountController.text);
    if (amount <= 0 || _seller == null) return;
    await ref
        .read(teamProvider.notifier)
        .createChallenge(
          TeamChallenge(
            date: _date,
            sellerId: _seller?.id,
            sellerName: _seller?.name,
            type: _type,
            amount: amount,
            notes: _notesController.text,
          ),
        );
    _amountController.clear();
    _notesController.clear();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.title,
    required this.state,
    required this.type,
  });

  final String title;
  final TeamState state;
  final TeamChallengeType type;

  @override
  Widget build(BuildContext context) {
    final ranking = state.challengeRanking(type: type);
    return PremiumCard(
      glowColor: _typeColor(type),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (ranking.isEmpty)
            const Text('Sem desafios nesta categoria.')
          else
            for (var index = 0; index < ranking.length; index++) ...[
              Row(
                children: [
                  Text('${index + 1}.'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ranking[index].sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${ranking[index].count}x'),
                  const SizedBox(width: 12),
                  Text(
                    money(ranking[index].amount),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              if (index != ranking.length - 1) const Divider(height: 20),
            ],
        ],
      ),
    );
  }
}

class _ChallengeList extends ConsumerWidget {
  const _ChallengeList({required this.state, required this.isLoading});

  final TeamState state;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = state.monthChallenges;
    if (entries.isEmpty) {
      return const PremiumCard(
        child: Text('Nenhum desafio registrado no mes.'),
      );
    }
    return Column(
      children: [
        for (final entry in entries) ...[
          PremiumCard(
            glowColor: _typeColor(entry.type),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.sellerName ?? 'Sem vendedor'} - ${entry.type.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_dateLabel(entry.date)}${entry.notes == null ? '' : ' | ${entry.notes}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFB6C2D3)),
                    ),
                  ],
                );
                final actions = Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _edit(context, ref, entry, state.sellers),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                    FilledButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _delete(context, ref, entry),
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Excluir'),
                    ),
                  ],
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      const SizedBox(height: 8),
                      Text(money(entry.amount)),
                      const SizedBox(height: 12),
                      actions,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: details),
                    Text(money(entry.amount)),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
              },
            ),
          ),
          if (entry != entries.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    TeamChallenge entry,
    List<Seller> sellers,
  ) async {
    final updated = await showModalBottomSheet<TeamChallenge>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ChallengeEditSheet(entry: entry, sellers: sellers),
    );
    if (updated != null) {
      await ref.read(teamProvider.notifier).updateChallenge(updated);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TeamChallenge entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir desafio?'),
        content: Text('Remover ${entry.type.label} de ${money(entry.amount)}?'),
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
      await ref.read(teamProvider.notifier).deleteChallenge(entry);
    }
  }
}

class _ChallengeEditSheet extends StatefulWidget {
  const _ChallengeEditSheet({required this.entry, required this.sellers});

  final TeamChallenge entry;
  final List<Seller> sellers;

  @override
  State<_ChallengeEditSheet> createState() => _ChallengeEditSheetState();
}

class _ChallengeEditSheetState extends State<_ChallengeEditSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _date;
  late TeamChallengeType _type;
  Seller? _seller;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _date = widget.entry.date;
    _type = widget.entry.type;
    _seller = widget.sellers
        .where((seller) => seller.id == widget.entry.sellerId)
        .firstOrNull;
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
        children: [
          _DateTile(date: _date, onTap: _pickDate),
          const SizedBox(height: 12),
          DropdownButtonFormField<Seller>(
            initialValue: widget.sellers.contains(_seller) ? _seller : null,
            decoration: const InputDecoration(labelText: 'Vendedor'),
            items: [
              for (final seller in widget.sellers)
                DropdownMenuItem(value: seller, child: Text(seller.name)),
            ],
            onChanged: (value) => setState(() => _seller = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TeamChallengeType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              for (final type in TeamChallengeType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor ganho'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Observacao'),
          ),
          const SizedBox(height: 16),
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

  void _save() {
    Navigator.of(context).pop(
      widget.entry.copyWith(
        date: _date,
        sellerId: _seller?.id,
        sellerName: _seller?.name,
        type: _type,
        amount: parseMoney(_amountController.text),
        notes: _notesController.text,
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
    if (selected != null) setState(() => _date = selected);
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.event_rounded),
              const SizedBox(width: 12),
              Expanded(child: Text('Data: ${_dateLabel(date)}')),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

Color _typeColor(TeamChallengeType type) {
  return switch (type) {
    TeamChallengeType.storeGoal => AppTheme.secondary,
    TeamChallengeType.biggestTicket => AppTheme.danger,
    TeamChallengeType.pa => AppTheme.warning,
  };
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
