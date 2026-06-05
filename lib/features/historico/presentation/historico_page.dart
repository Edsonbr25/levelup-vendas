import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/equipe/application/team_controller.dart';
import '../../../features/equipe/domain/team_state.dart';
import '../../../shared/widgets/animated_action_button.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_card.dart';

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  late int _month = DateTime.now().month;
  late int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(teamProvider);
    final state = asyncState.value ?? TeamState.mock();

    if (asyncState.isLoading && !asyncState.hasValue) {
      return const _HistoricoSkeleton();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        DataStatusBanner(
          state: state,
          isLoading: asyncState.isLoading,
          onRefresh: () => ref.read(teamProvider.notifier).refresh(),
        ),
        Text(
          'Historico',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        _PeriodFilter(
          month: _month,
          year: _year,
          onChanged: (month, year) {
            setState(() {
              _month = month;
              _year = year;
            });
            ref
                .read(teamProvider.notifier)
                .setPeriod(
                  DateTime(year, month),
                  DateTime(year, month + 1).subtract(const Duration(days: 1)),
                );
          },
        ),
        const SizedBox(height: 22),
        _ExportHeader(state: state),
        const SizedBox(height: 22),
        ResponsiveGrid(
          children: [
            StatCard(
              title: 'Venda loja',
              value: money(state.monthlyStoreSales),
              subtitle: 'Total no periodo',
              icon: Icons.storefront_rounded,
            ),
            StatCard(
              title: 'Venda equipe',
              value: money(state.monthlyTeamSales),
              subtitle: 'Somatorio por vendedor',
              icon: Icons.groups_rounded,
              color: AppTheme.secondary,
            ),
            StatCard(
              title: 'Comissao estimada',
              value: money(state.estimatedCommissionTotal),
              subtitle: 'Regras atuais de comissao',
              icon: Icons.payments_rounded,
              color: AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Resumo por vendedor',
          child: _SellerSummary(state: state),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Historico de vendas',
          child: _SalesTable(state: state),
        ),
      ],
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({
    required this.month,
    required this.year,
    required this.onChanged,
  });

  final int month;
  final int year;
  final void Function(int month, int year) onChanged;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    return PremiumCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final monthField = DropdownButtonFormField<int>(
            initialValue: month,
            decoration: const InputDecoration(labelText: 'Mes'),
            items: [
              for (var item = 1; item <= 12; item++)
                DropdownMenuItem(value: item, child: Text(_monthName(item))),
            ],
            onChanged: (value) => onChanged(value ?? month, year),
          );
          final yearField = DropdownButtonFormField<int>(
            initialValue: year,
            decoration: const InputDecoration(labelText: 'Ano'),
            items: [
              for (var item = currentYear - 4; item <= currentYear + 1; item++)
                DropdownMenuItem(value: item, child: Text('$item')),
            ],
            onChanged: (value) => onChanged(month, value ?? year),
          );
          return constraints.maxWidth >= 620
              ? Row(
                  children: [
                    Expanded(child: monthField),
                    const SizedBox(width: 12),
                    Expanded(child: yearField),
                  ],
                )
              : Column(
                  children: [monthField, const SizedBox(height: 12), yearField],
                );
        },
      ),
    );
  }
}

class _ExportHeader extends StatelessWidget {
  const _ExportHeader({required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 620;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Relatorio de vendas e comissoes',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                '${_dateLabel(state.periodStart)} a ${_dateLabel(state.periodEnd)}',
                style: const TextStyle(color: Color(0xFFB6C2D3)),
              ),
            ],
          );
          final button = AnimatedActionButton(
            onPressed: () async {
              final pdf = await _buildPdf(state);
              await Printing.layoutPdf(
                name: 'levelup-vendas-equipe.pdf',
                onLayout: (_) async => pdf,
              );
            },
            icon: Icons.picture_as_pdf_rounded,
            label: 'Exportar PDF',
            expand: isMobile,
          );
          return isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [content, const SizedBox(height: 16), button],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 16),
                    SizedBox(width: 220, child: button),
                  ],
                );
        },
      ),
    );
  }
}

class _SellerSummary extends StatelessWidget {
  const _SellerSummary({required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    if (state.salesRanking.isEmpty) {
      return const PremiumCard(child: Text('Nenhuma venda por vendedor.'));
    }
    return Column(
      children: [
        for (final ranking in state.salesRanking) ...[
          PremiumCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ranking.seller.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(money(ranking.monthlySales)),
              ],
            ),
          ),
          if (ranking != state.salesRanking.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    if (state.monthSales.isEmpty) {
      return const PremiumCard(child: Text('Sem vendas no periodo.'));
    }
    return PremiumCard(
      child: Column(
        children: [
          for (final sale in state.monthSales) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_dateLabel(sale.date)} - ${sale.sellerName ?? 'Loja'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(sale.type.label),
                const SizedBox(width: 12),
                Text(
                  money(sale.amount),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if (sale != state.monthSales.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _HistoricoSkeleton extends StatelessWidget {
  const _HistoricoSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: const [
        LoadingSkeleton(height: 140),
        SizedBox(height: 14),
        LoadingSkeleton(height: 240),
      ],
    );
  }
}

Future<Uint8List> _buildPdf(TeamState state) async {
  final document = pw.Document(
    title: 'Relatorio LevelUp Vendas',
    author: AppConstants.userName,
  );
  document.addPage(
    pw.MultiPage(
      pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
      build: (context) => [
        pw.Text(
          AppConstants.appName,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(AppConstants.storeName),
        pw.SizedBox(height: 18),
        pw.Text(
          'Periodo: ${_dateLabel(state.periodStart)} a ${_dateLabel(state.periodEnd)}',
        ),
        pw.SizedBox(height: 14),
        pw.Text('Venda loja: ${money(state.monthlyStoreSales)}'),
        pw.Text('Venda equipe: ${money(state.monthlyTeamSales)}'),
        pw.Text('Comissao estimada: ${money(state.estimatedCommissionTotal)}'),
        pw.SizedBox(height: 18),
        pw.Text(
          'Resumo por vendedor',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Vendedor', 'Vendas', 'Meta mes'],
          data: [
            for (final ranking in state.salesRanking)
              [
                ranking.seller.name,
                money(ranking.monthlySales),
                percent(ranking.monthlyPercent),
              ],
          ],
          border: pw.TableBorder.all(color: PdfColors.grey300),
        ),
      ],
    ),
  );
  return document.save();
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _monthName(int month) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return months[month - 1];
}
