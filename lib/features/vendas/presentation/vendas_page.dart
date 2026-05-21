import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/gamificacao/application/level_up_controller.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../features/vendas/data/vendas_repository.dart';
import '../../../features/vendas/domain/sale_entry.dart';
import '../../../shared/widgets/animated_action_button.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/money_field.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/progress_metric_card.dart';
import '../../../shared/widgets/stat_card.dart';

final salesHistoryProvider = FutureProvider.autoDispose<List<SaleEntry>>((
  ref,
) async {
  return ref.watch(vendasRepositoryProvider).listSales();
});

class VendasPage extends ConsumerStatefulWidget {
  const VendasPage({super.key});

  @override
  ConsumerState<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends ConsumerState<VendasPage> {
  double _individualSale = 0;
  double _storeSale = 0;
  DateTime _saleDate = _yesterday();
  int _formVersion = 0;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(levelUpProvider);
    final state = asyncState.value ?? LevelUpState.initialMock();
    final salesHistory = ref.watch(salesHistoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        DataStatusBanner(
          state: state,
          isLoading: asyncState.isLoading,
          onRefresh: () {
            ref.read(levelUpProvider.notifier).refresh();
            ref.invalidate(salesHistoryProvider);
          },
        ),
        Text(
          'Vendas',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AppSection(
          title: 'Lancamento diario',
          child: PremiumCard(
            child: Column(
              children: [
                _DatePickerTile(
                  label: 'Data da venda',
                  date: _saleDate,
                  onTap: _pickSaleDate,
                ),
                const SizedBox(height: 12),
                MoneyField(
                  key: ValueKey('individual-sale-$_formVersion'),
                  label: 'Venda individual diaria',
                  initialValue: _individualSale,
                  onChanged: (value) => _individualSale = parseMoney(value),
                ),
                const SizedBox(height: 12),
                MoneyField(
                  key: ValueKey('store-sale-$_formVersion'),
                  label: 'Venda loja diaria',
                  initialValue: _storeSale,
                  onChanged: (value) => _storeSale = parseMoney(value),
                ),
                const SizedBox(height: 18),
                AnimatedActionButton(
                  onPressed: asyncState.isLoading ? null : _createSale,
                  icon: Icons.check_circle_rounded,
                  label: 'Salvar venda',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ProgressMetricCard(
          title: 'Percentual mensal individual',
          value: state.monthlyIndividualPercent,
          subtitle:
              '${money(state.monthlyIndividualSales)} no mes | comissao ${state.individualCommissionRate}%',
        ),
        const SizedBox(height: 14),
        ProgressMetricCard(
          title: 'Percentual mensal loja',
          value: state.monthlyStorePercent,
          subtitle:
              '${money(state.monthlyStoreSales)} no mes | comissao ${state.storeCommissionRate}%',
          color: AppTheme.secondary,
        ),
        const SizedBox(height: 14),
        StatCard(
          title: 'Comissao atualizada',
          value: money(state.estimatedCommission),
          subtitle: 'Calculada com os totais reais do mes',
          icon: Icons.payments_rounded,
          color: AppTheme.warning,
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Historico de vendas',
          child: salesHistory.when(
            loading: () => const PremiumCard(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => PremiumCard(
              glowColor: AppTheme.danger,
              child: Text('Erro ao carregar vendas: $error'),
            ),
            data: (sales) =>
                _SalesHistory(sales: sales, isLoading: asyncState.isLoading),
          ),
        ),
      ],
    );
  }

  Future<void> _pickSaleDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (selected != null) {
      setState(() => _saleDate = selected);
    }
  }

  Future<void> _createSale() async {
    await ref
        .read(levelUpProvider.notifier)
        .createSale(
          SaleEntry(
            date: _saleDate,
            individualSale: _individualSale,
            storeSale: _storeSale,
          ),
        );
    ref.invalidate(salesHistoryProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Venda salva com sucesso.')));
    }
    setState(() {
      _individualSale = 0;
      _storeSale = 0;
      _saleDate = _yesterday();
      _formVersion++;
    });
  }

  static DateTime _yesterday() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
  }
}

class _SalesHistory extends ConsumerWidget {
  const _SalesHistory({required this.sales, required this.isLoading});

  final List<SaleEntry> sales;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sales.isEmpty) {
      return const PremiumCard(child: Text('Nenhuma venda cadastrada ainda.'));
    }

    return Column(
      children: [
        for (final sale in sales.take(40)) ...[
          _SaleHistoryItem(
            sale: sale,
            isLoading: isLoading,
            onEdit: sale.id == null || isLoading
                ? null
                : () => _showEditSheet(context, ref, sale),
            onDelete: sale.id == null || isLoading
                ? null
                : () => _confirmDelete(context, ref, sale),
          ),
          if (sale != sales.take(40).last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    SaleEntry sale,
  ) async {
    final updated = await showModalBottomSheet<SaleEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _EditSaleSheet(sale: sale),
    );

    if (updated != null) {
      await ref.read(levelUpProvider.notifier).updateSale(updated);
      ref.invalidate(salesHistoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda atualizada com sucesso.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SaleEntry sale,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir venda?'),
        content: Text(
          'Esta acao removera a venda de ${_dateLabel(sale.date)}.',
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
      await ref.read(levelUpProvider.notifier).deleteSale(sale);
      ref.invalidate(salesHistoryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venda excluida com sucesso.')),
        );
      }
    }
  }
}

class _SaleHistoryItem extends StatelessWidget {
  const _SaleHistoryItem({
    required this.sale,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
  });

  final SaleEntry sale;
  final bool isLoading;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: AppTheme.secondary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = [
            _SaleMetric(
              label: 'Data',
              value: _dateLabel(sale.date),
              icon: Icons.event_rounded,
            ),
            _SaleMetric(
              label: 'Individual',
              value: money(sale.individualSale),
              icon: Icons.person_rounded,
            ),
            _SaleMetric(
              label: 'Loja',
              value: money(sale.storeSale),
              icon: Icons.storefront_rounded,
            ),
          ];
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: isLoading ? null : onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar'),
              ),
              FilledButton.icon(
                onPressed: isLoading ? null : onDelete,
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Excluir'),
              ),
            ],
          );

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in content) ...[
                  item,
                  if (item != content.last) const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: actions),
              ],
            );
          }

          return Row(
            children: [
              for (final item in content) Expanded(child: item),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SaleMetric extends StatelessWidget {
  const _SaleMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB6C2D3)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditSaleSheet extends StatefulWidget {
  const _EditSaleSheet({required this.sale});

  final SaleEntry sale;

  @override
  State<_EditSaleSheet> createState() => _EditSaleSheetState();
}

class _EditSaleSheetState extends State<_EditSaleSheet> {
  late final TextEditingController _individualController;
  late final TextEditingController _storeController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _individualController = TextEditingController(
      text: widget.sale.individualSale.toStringAsFixed(2).replaceAll('.', ','),
    );
    _storeController = TextEditingController(
      text: widget.sale.storeSale.toStringAsFixed(2).replaceAll('.', ','),
    );
    _date = widget.sale.date;
  }

  @override
  void dispose() {
    _individualController.dispose();
    _storeController.dispose();
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
            'Editar venda',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _DatePickerTile(
            label: 'Data da venda',
            date: _date,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _individualController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Venda individual diaria',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _storeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Venda loja diaria',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
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
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  void _save() {
    Navigator.of(context).pop(
      widget.sale.copyWith(
        date: _date,
        individualSale: parseMoney(_individualController.text),
        storeSale: parseMoney(_storeController.text),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
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
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
