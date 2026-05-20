import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../desafios/domain/challenge_entry.dart';
import '../domain/historical_report.dart';

final historicoRepositoryProvider = Provider<HistoricoRepository>((ref) {
  return HistoricoRepository(ref.watch(supabaseClientProvider));
});

class HistoricoRepository {
  const HistoricoRepository(this._client);

  final SupabaseClient? _client;

  Future<HistoricalReport> fetchReport(HistoryPeriod period) async {
    if (_client == null) {
      throw StateError('Supabase nao configurado.');
    }

    final metasRows = await _client
        .from('metas')
        .select()
        .lte('created_at', period.endExclusive.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);
    final vendasRows = await _client
        .from('vendas')
        .select()
        .gte('sale_date', _dateOnly(period.start))
        .lt('sale_date', _dateOnly(period.endExclusive))
        .order('sale_date');
    final desafiosRows = await _client
        .from('desafios')
        .select()
        .gte('challenge_date', _dateOnly(period.start))
        .lt('challenge_date', _dateOnly(period.endExclusive))
        .order('challenge_date', ascending: false);

    final metas = metasRows.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(metasRows.first);
    final defaultWeekStart = period.start;
    final defaultWeekEnd = DateTime(
      period.year,
      period.month,
      period.daysInMonth < 7 ? period.daysInMonth : 7,
    );
    final weeklyStartDate = _validDate(
      metas['weekly_start_date'],
      defaultWeekStart,
    );
    final parsedWeeklyEndDate = _validDate(
      metas['weekly_end_date'],
      defaultWeekEnd,
    );
    final weeklyEndDate = parsedWeeklyEndDate.isBefore(weeklyStartDate)
        ? weeklyStartDate
        : parsedWeeklyEndDate;
    final salesByDay = <int, DaySales>{};
    var individualTotal = 0.0;
    var storeTotal = 0.0;

    for (final raw in vendasRows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final date = DateTime.tryParse(row['sale_date']?.toString() ?? '');
      if (date == null) continue;
      final individual = _toDouble(row['daily_individual_sale']);
      final store = _toDouble(row['daily_store_sale']);
      individualTotal += individual;
      storeTotal += store;
      final current =
          salesByDay[date.day] ?? const DaySales(individual: 0, store: 0);
      salesByDay[date.day] = current.add(individual: individual, store: store);
    }

    return HistoricalReport(
      period: period,
      monthlyIndividualGoal: _toDouble(metas['monthly_individual_goal']),
      weeklyIndividualGoal: _toDouble(metas['weekly_individual_goal']),
      monthlyStoreGoal: _toDouble(metas['monthly_store_goal']),
      weeklyStoreGoal: _toDouble(metas['weekly_store_goal']),
      weeklyStartDate: weeklyStartDate,
      weeklyEndDate: weeklyEndDate,
      individualSalesTotal: individualTotal,
      storeSalesTotal: storeTotal,
      challenges: _parseChallenges(desafiosRows),
      salesByDay: salesByDay,
      isFallback: false,
    );
  }

  List<ChallengeEntry> _parseChallenges(List<dynamic> rows) {
    final entries = <ChallengeEntry>[];
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      if (row.containsKey('challenge_type')) {
        entries.add(ChallengeEntry.fromSupabase(row));
      } else {
        entries.addAll(ChallengeEntry.legacyFromSupabase(row));
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }

  DateTime _validDate(Object? value, DateTime fallback) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return fallback;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
