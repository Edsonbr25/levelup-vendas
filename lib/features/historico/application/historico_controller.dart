import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/historico_repository.dart';
import '../domain/historical_report.dart';

final selectedHistoryPeriodProvider =
    NotifierProvider<HistoryPeriodController, HistoryPeriod>(
      HistoryPeriodController.new,
    );

class HistoryPeriodController extends Notifier<HistoryPeriod> {
  @override
  HistoryPeriod build() {
    final now = DateTime.now();
    return HistoryPeriod(month: now.month, year: now.year);
  }

  void setPeriod(HistoryPeriod period) {
    state = period;
  }
}

final historicoReportProvider = FutureProvider<HistoricalReport>((ref) async {
  final period = ref.watch(selectedHistoryPeriodProvider);
  try {
    return await ref.read(historicoRepositoryProvider).fetchReport(period);
  } catch (error) {
    debugPrint('Historico fallback after load error: $error');
    return HistoricalReport.fallback(period);
  }
});
