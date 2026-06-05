import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/equipe/application/team_controller.dart';
import '../../../features/equipe/domain/seller.dart';
import '../../../features/equipe/domain/team_sale.dart';
import '../../../features/equipe/domain/team_state.dart';
import '../../../shared/widgets/animated_action_button.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/premium_card.dart';

class VendasPage extends ConsumerStatefulWidget {
  const VendasPage({super.key});

  @override
  ConsumerState<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends ConsumerState<VendasPage> {
  final _amountController = TextEditingController();
  DateTime _saleDate = DateTime.now().subtract(const Duration(days: 1));
  SaleType _saleType = SaleType.seller;
  Seller? _seller;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(teamProvider);
    final state = asyncState.value ?? TeamState.mock();

    if (asyncState.isLoading && !asyncState.hasValue) {
      return const _SalesSkeleton();
    }

    if (_seller != null &&
        !state.sellers.any((seller) => seller.id == _seller?.id)) {
      _seller = null;
    }
    if (_saleType == SaleType.seller &&
        _seller == null &&
        state.sellers.isNotEmpty) {
      _seller = state.sellers.first;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        DataStatusBanner(
          state: state,
          isLoading: asyncState.isLoading,
          onRefresh: () => ref.read(teamProvider.notifier).refresh(),
        ),
        SizedBox(
          width: double.infinity,
          child: Text(
            'Vendas',
            textAlign: MediaQuery.sizeOf(context).width < 430
                ? TextAlign.center
                : TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 20),
        if (state.sellers.isEmpty) ...[
          const _NoSellersWarning(),
          const SizedBox(height: 18),
        ],
        AppSection(
          title: 'Registrar venda',
          child: PremiumCard(
            child: Column(
              children: [
                _DateTile(
                  label: 'Data da venda',
                  date: _saleDate,
                  onTap: _pickSaleDate,
                ),
                const SizedBox(height: 12),
                SegmentedButton<SaleType>(
                  segments: const [
                    ButtonSegment(
                      value: SaleType.seller,
                      label: Text('Vendedor'),
                      icon: Icon(Icons.person_rounded),
                    ),
                    ButtonSegment(
                      value: SaleType.store,
                      label: Text('Loja'),
                      icon: Icon(Icons.storefront_rounded),
                    ),
                  ],
                  selected: {_saleType},
                  onSelectionChanged: (value) {
                    setState(() => _saleType = value.first);
                  },
                ),
                if (state.sellers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Seller?>(
                    initialValue:
                        state.sellers.any((seller) => seller.id == _seller?.id)
                        ? _seller
                        : null,
                    decoration: InputDecoration(
                      labelText: _saleType == SaleType.store
                          ? 'Vendedor (opcional)'
                          : 'Vendedor',
                      prefixIcon: const Icon(Icons.people_rounded),
                    ),
                    items: [
                      if (_saleType == SaleType.store)
                        const DropdownMenuItem<Seller?>(
                          value: null,
                          child: Text('Sem vendedor / venda loja'),
                        ),
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
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor da venda',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedActionButton(
                  onPressed: asyncState.isLoading ? null : () => _createSale(),
                  icon: Icons.point_of_sale_rounded,
                  label: 'Salvar venda',
                  expand: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Historico de vendas do mes',
          child: _SalesHistory(state: state, isLoading: asyncState.isLoading),
        ),
      ],
    );
  }

  Future<void> _createSale() async {
    final amount = parseMoney(_amountController.text);
    if (amount <= 0) return;
    if (_saleType == SaleType.seller && _seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre vendedores na tela Metas para registrar vendas individuais.',
          ),
        ),
      );
      return;
    }
    await ref
        .read(teamProvider.notifier)
        .createSale(
          TeamSale(
            date: _saleDate,
            sellerId: _seller?.id,
            sellerName: _seller?.name ?? 'Loja',
            amount: amount,
            type: _saleType,
          ),
        );
    _amountController.clear();
  }

  Future<void> _pickSaleDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _saleDate = selected);
  }
}

class _NoSellersWarning extends StatelessWidget {
  const _NoSellersWarning();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;

        return PremiumCard(
          glowColor: AppTheme.warning,
          child: isCompact
              ? const Column(
                  children: [
                    Icon(Icons.info_rounded, color: AppTheme.warning),
                    SizedBox(height: 10),
                    Text(
                      'Cadastre vendedores na tela Metas para registrar vendas individuais.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE7D7AA),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_rounded, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cadastre vendedores na tela Metas para registrar vendas individuais.',
                        style: TextStyle(
                          color: Color(0xFFE7D7AA),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CenteredEmptyCard extends StatelessWidget {
  const _CenteredEmptyCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: SizedBox(
        width: double.infinity,
        child: Text(
          message,
          textAlign: MediaQuery.sizeOf(context).width < 430
              ? TextAlign.center
              : TextAlign.start,
        ),
      ),
    );
  }
}

class _SalesHistory extends ConsumerWidget {
  const _SalesHistory({required this.state, required this.isLoading});

  final TeamState state;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = state.monthSales;
    if (sales.isEmpty) {
      return const _CenteredEmptyCard('Nenhuma venda neste mes.');
    }
    return Column(
      children: [
        for (final sale in sales) ...[
          PremiumCard(
            glowColor: sale.type == SaleType.store
                ? AppTheme.secondary
                : AppTheme.primary,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;
                final details = Column(
                  crossAxisAlignment: isCompact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.sellerName ?? 'Loja',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isCompact ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_dateLabel(sale.date)} | ${sale.type.label}',
                      textAlign: isCompact ? TextAlign.center : TextAlign.start,
                      style: const TextStyle(color: Color(0xFFB6C2D3)),
                    ),
                  ],
                );
                final value = Text(
                  money(sale.amount),
                  textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                );
                final actions = Wrap(
                  alignment: isCompact
                      ? WrapAlignment.center
                      : WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _editSale(context, ref, sale, state.sellers),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                    FilledButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => _deleteSale(context, ref, sale),
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Excluir'),
                    ),
                  ],
                );
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      details,
                      const SizedBox(height: 10),
                      value,
                      const SizedBox(height: 14),
                      actions,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: details),
                    value,
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
              },
            ),
          ),
          if (sale != sales.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _editSale(
    BuildContext context,
    WidgetRef ref,
    TeamSale sale,
    List<Seller> sellers,
  ) async {
    final updated = await showModalBottomSheet<TeamSale>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _SaleEditSheet(sale: sale, sellers: sellers),
    );
    if (updated != null) {
      await ref.read(teamProvider.notifier).updateSale(updated);
    }
  }

  Future<void> _deleteSale(
    BuildContext context,
    WidgetRef ref,
    TeamSale sale,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir venda?'),
        content: Text('Remover venda de ${money(sale.amount)}?'),
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
      await ref.read(teamProvider.notifier).deleteSale(sale);
    }
  }
}

class _SaleEditSheet extends StatefulWidget {
  const _SaleEditSheet({required this.sale, required this.sellers});

  final TeamSale sale;
  final List<Seller> sellers;

  @override
  State<_SaleEditSheet> createState() => _SaleEditSheetState();
}

class _SaleEditSheetState extends State<_SaleEditSheet> {
  late final TextEditingController _amountController;
  late DateTime _date;
  late SaleType _type;
  Seller? _seller;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.sale.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _date = widget.sale.date;
    _type = widget.sale.type;
    _seller = widget.sellers
        .where((seller) => seller.id == widget.sale.sellerId)
        .firstOrNull;
  }

  @override
  void dispose() {
    _amountController.dispose();
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
          _DateTile(label: 'Data da venda', date: _date, onTap: _pickDate),
          const SizedBox(height: 12),
          DropdownButtonFormField<SaleType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              for (final type in SaleType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          if (widget.sellers.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<Seller?>(
              initialValue:
                  widget.sellers.any((seller) => seller.id == _seller?.id)
                  ? _seller
                  : null,
              decoration: InputDecoration(
                labelText: _type == SaleType.store
                    ? 'Vendedor (opcional)'
                    : 'Vendedor',
              ),
              items: [
                if (_type == SaleType.store)
                  const DropdownMenuItem<Seller?>(
                    value: null,
                    child: Text('Sem vendedor / venda loja'),
                  ),
                for (final seller in widget.sellers)
                  DropdownMenuItem(value: seller, child: Text(seller.name)),
              ],
              onChanged: (value) => setState(() => _seller = value),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor'),
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

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _save() {
    if (_type == SaleType.seller && _seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre vendedores na tela Metas para registrar vendas individuais.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      widget.sale.copyWith(
        date: _date,
        type: _type,
        sellerId: _seller?.id,
        sellerName: _seller?.name ?? 'Loja',
        amount: parseMoney(_amountController.text),
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.event_rounded),
              const SizedBox(width: 12),
              Expanded(child: Text('$label: ${_dateLabel(date)}')),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesSkeleton extends StatelessWidget {
  const _SalesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: const [
        LoadingSkeleton(height: 180),
        SizedBox(height: 14),
        LoadingSkeleton(height: 220),
      ],
    );
  }
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
