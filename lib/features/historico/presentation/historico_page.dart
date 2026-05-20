import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/animated_action_button.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/history_chart_card.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../desafios/domain/challenge_entry.dart';
import '../application/historico_controller.dart';
import '../data/historico_pdf_service.dart';
import '../domain/historical_report.dart';

class HistoricoPage extends ConsumerWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedHistoryPeriodProvider);
    final report = ref.watch(historicoReportProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Historico',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PeriodFilter(period: period),
        const SizedBox(height: 22),
        report.when(
          loading: () => const _HistoricoSkeleton(),
          error: (error, stackTrace) => PremiumCard(
            glowColor: AppTheme.danger,
            child: Text('Erro ao carregar historico: $error'),
          ),
          data: (data) => _ReportContent(report: data),
        ),
      ],
    );
  }
}

class _PeriodFilter extends ConsumerWidget {
  const _PeriodFilter({required this.period});

  final HistoryPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentYear = DateTime.now().year;

    return PremiumCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final month = DropdownButtonFormField<int>(
            initialValue: period.month,
            decoration: const InputDecoration(labelText: 'Mes'),
            items: [
              for (var month = 1; month <= 12; month++)
                DropdownMenuItem(value: month, child: Text(_monthName(month))),
            ],
            onChanged: (value) {
              if (value == null) return;
              ref
                  .read(selectedHistoryPeriodProvider.notifier)
                  .setPeriod(HistoryPeriod(month: value, year: period.year));
            },
          );
          final year = DropdownButtonFormField<int>(
            initialValue: period.year,
            decoration: const InputDecoration(labelText: 'Ano'),
            items: [
              for (var year = currentYear - 4; year <= currentYear + 1; year++)
                DropdownMenuItem(value: year, child: Text('$year')),
            ],
            onChanged: (value) {
              if (value == null) return;
              ref
                  .read(selectedHistoryPeriodProvider.notifier)
                  .setPeriod(HistoryPeriod(month: period.month, year: value));
            },
          );

          return isWide
              ? Row(
                  children: [
                    Expanded(child: month),
                    const SizedBox(width: 12),
                    Expanded(child: year),
                  ],
                )
              : Column(children: [month, const SizedBox(height: 12), year]);
        },
      ),
    );
  }

  static String _monthName(int month) {
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
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report});

  final HistoricalReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (report.isFallback) ...[
          PremiumCard(
            glowColor: AppTheme.warning,
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: AppTheme.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.errorMessage ??
                        'Usando dados locais temporarios para o historico.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        _ExportHeader(report: report),
        const SizedBox(height: 22),
        ResponsiveGrid(
          children: [
            StatCard(
              title: 'Vendas totais',
              value: money(report.totalSales),
              subtitle:
                  '${money(report.individualSalesTotal)} ind. | ${money(report.storeSalesTotal)} loja',
              icon: Icons.point_of_sale_rounded,
            ),
            StatCard(
              title: 'Comissao',
              value: money(report.estimatedCommission),
              subtitle:
                  'Ind. ${report.individualCommissionRate}% | Loja ${report.storeCommissionRate}%',
              icon: Icons.payments_rounded,
              color: AppTheme.warning,
            ),
            StatCard(
              title: 'Ganhos extras',
              value: money(report.challengeTotal),
              subtitle: 'Desafios no periodo',
              icon: Icons.emoji_events_rounded,
              color: AppTheme.secondary,
            ),
            StatCard(
              title: 'XP e nivel',
              value: '${report.xp} XP',
              subtitle: 'Nivel ${report.level}',
              icon: Icons.bolt_rounded,
              color: AppTheme.danger,
            ),
            StatCard(
              title: 'Streak',
              value: '${report.streak} dias',
              subtitle: 'Maior sequencia do periodo',
              icon: Icons.local_fire_department_rounded,
              color: AppTheme.danger,
            ),
            StatCard(
              title: 'Metas atingidas',
              value: '${report.goalsReached}/2',
              subtitle: 'Individual e loja',
              icon: Icons.flag_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Graficos historicos',
          child: HistoryChartCard(
            title: 'Vendas por dia em ${report.period.label}',
            primaryValues: report.individualChart,
            secondaryValues: report.storeChart,
          ),
        ),
        const SizedBox(height: 24),
        AppSection(
          title: 'Desafios no periodo',
          child: ResponsiveGrid(
            children: [
              StatCard(
                title: ChallengeType.storeGoal.label,
                value: money(
                  report.challengeTotalByType(ChallengeType.storeGoal),
                ),
                icon: Icons.storefront_rounded,
                color: AppTheme.secondary,
              ),
              StatCard(
                title: ChallengeType.pa.label,
                value: money(report.challengeTotalByType(ChallengeType.pa)),
                icon: Icons.groups_rounded,
                color: AppTheme.warning,
              ),
              StatCard(
                title: ChallengeType.biggestTicket.label,
                value: money(
                  report.challengeTotalByType(ChallengeType.biggestTicket),
                ),
                icon: Icons.receipt_long_rounded,
                color: AppTheme.danger,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportHeader extends StatelessWidget {
  const _ExportHeader({required this.report});

  final HistoricalReport report;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatorio ${report.period.label}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'PDF profissional com vendas, comissao, desafios, graficos e resumo final.',
                  style: TextStyle(color: Color(0xFFB6C2D3)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 210,
            child: AnimatedActionButton(
              onPressed: () async {
                final pdf = await const HistoricoPdfService().build(report);
                await Printing.layoutPdf(
                  name:
                      'levelup-vendas-${report.period.month}-${report.period.year}.pdf',
                  onLayout: (_) async => pdf,
                );
              },
              icon: Icons.picture_as_pdf_rounded,
              label: 'Exportar PDF',
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricoSkeleton extends StatelessWidget {
  const _HistoricoSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        LoadingSkeleton(height: 140),
        SizedBox(height: 14),
        LoadingSkeleton(height: 190),
        SizedBox(height: 14),
        LoadingSkeleton(height: 280),
      ],
    );
  }
}
