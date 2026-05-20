import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../desafios/domain/challenge_entry.dart';
import '../domain/historical_report.dart';

class HistoricoPdfService {
  const HistoricoPdfService();

  Future<Uint8List> build(HistoricalReport report) async {
    final logoBytes = await rootBundle.load('web/icons/Icon-192.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final document = pw.Document(
      title: 'Relatorio LevelUp Vendas - ${report.period.label}',
      author: AppConstants.userName,
      creator: AppConstants.appName,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          _header(report, logo),
          pw.SizedBox(height: 22),
          _sectionTitle('Resumo do periodo'),
          pw.SizedBox(height: 10),
          _metricGrid([
            _PdfMetric('Vendas totais', money(report.totalSales)),
            _PdfMetric('Comissao', money(report.estimatedCommission)),
            _PdfMetric('Ganhos extras', money(report.challengeTotal)),
            _PdfMetric('XP', '${report.xp}'),
            _PdfMetric('Nivel', report.level),
            _PdfMetric('Streak', '${report.streak} dias'),
            _PdfMetric('Metas atingidas', '${report.goalsReached}/2'),
            _PdfMetric('Periodo', report.period.label),
          ]),
          pw.SizedBox(height: 22),
          _sectionTitle('Vendas'),
          pw.SizedBox(height: 8),
          _chart(
            title: 'Vendas por dia',
            labels: [
              for (var day = 1; day <= report.period.daysInMonth; day++) '$day',
            ],
            primary: report.individualChart,
            secondary: report.storeChart,
            primaryLabel: 'Individual',
            secondaryLabel: 'Loja',
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('Ganhos em desafios'),
          pw.SizedBox(height: 8),
          _metricGrid([
            _PdfMetric(
              ChallengeType.storeGoal.label,
              money(report.challengeTotalByType(ChallengeType.storeGoal)),
            ),
            _PdfMetric(
              ChallengeType.pa.label,
              money(report.challengeTotalByType(ChallengeType.pa)),
            ),
            _PdfMetric(
              ChallengeType.biggestTicket.label,
              money(report.challengeTotalByType(ChallengeType.biggestTicket)),
            ),
          ]),
          pw.SizedBox(height: 18),
          _challengeTable(report),
          pw.SizedBox(height: 22),
          _sectionTitle('Resumo final'),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: _boxDecoration(),
            child: pw.Text(
              'No periodo ${report.period.label}, ${AppConstants.userName} registrou ${money(report.totalSales)} em vendas, ${money(report.estimatedCommission)} em comissao estimada e ${money(report.challengeTotal)} em ganhos extras de desafios. Nivel final: ${report.level}.',
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 4),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(HistoricalReport report, pw.ImageProvider logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#090B10'),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Row(
        children: [
          pw.Container(width: 54, height: 54, child: pw.Image(logo)),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  AppConstants.appName,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${AppConstants.userName} | ${AppConstants.userRole}',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#B6C2D3'),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#39F0AE'),
              borderRadius: pw.BorderRadius.circular(999),
            ),
            child: pw.Text(
              report.period.label,
              style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _metricGrid(List<_PdfMetric> metrics) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final metric in metrics)
          pw.Container(
            width: 122,
            padding: const pw.EdgeInsets.all(12),
            decoration: _boxDecoration(),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  metric.label,
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#667085'),
                    fontSize: 8,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  metric.value,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _chart({
    required String title,
    required List<String> labels,
    required List<double> primary,
    required List<double> secondary,
    required String primaryLabel,
    required String secondaryLabel,
  }) {
    final maxValue = [
      ...primary,
      ...secondary,
      1.0,
    ].reduce((value, item) => value > item ? value : item);
    final displayEvery = labels.length > 16 ? 3 : 1;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              _legend(primaryLabel, PdfColor.fromHex('#39F0AE')),
              pw.SizedBox(width: 10),
              _legend(secondaryLabel, PdfColor.fromHex('#6CC7FF')),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < labels.length; index++)
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        height: 80,
                        alignment: pw.Alignment.bottomCenter,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            _bar(
                              primary[index],
                              maxValue,
                              PdfColor.fromHex('#39F0AE'),
                            ),
                            pw.SizedBox(width: 1.4),
                            _bar(
                              secondary[index],
                              maxValue,
                              PdfColor.fromHex('#6CC7FF'),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        index % displayEvery == 0 ? labels[index] : '',
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _bar(double value, double maxValue, PdfColor color) {
    final height = maxValue <= 0 ? 0.0 : (value / maxValue) * 78;
    return pw.Container(
      width: 3.2,
      height: height.clamp(1, 78).toDouble(),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
    );
  }

  pw.Widget _legend(String label, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 7, height: 7, color: color),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  pw.Widget _challengeTable(HistoricalReport report) {
    if (report.challenges.isEmpty) {
      return pw.Text('Nenhum desafio registrado no periodo.');
    }

    return pw.TableHelper.fromTextArray(
      headers: const ['Data', 'Tipo', 'Valor', 'Observacao'],
      data: [
        for (final entry in report.challenges)
          [
            _dateLabel(entry.date),
            entry.typeLabel,
            money(entry.amount),
            entry.notes ?? '',
          ],
      ],
      border: null,
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#11151D')),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.all(7),
      oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F7F9FC')),
    );
  }

  pw.BoxDecoration _boxDecoration() {
    return pw.BoxDecoration(
      color: PdfColor.fromHex('#FFFFFF'),
      border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
      borderRadius: pw.BorderRadius.circular(12),
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _PdfMetric {
  const _PdfMetric(this.label, this.value);

  final String label;
  final String value;
}
