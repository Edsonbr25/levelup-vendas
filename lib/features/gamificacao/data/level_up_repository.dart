import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../desafios/domain/challenge_entry.dart';
import '../domain/level_up_state.dart';

final levelUpRepositoryProvider = Provider<LevelUpRepository>((ref) {
  return LevelUpRepository(ref.watch(supabaseClientProvider));
});

class LevelUpRepository {
  const LevelUpRepository(this._client);

  final SupabaseClient? _client;

  bool get isConnected => _client != null;

  Future<LevelUpState> fetchDashboardState() async {
    if (_client == null) {
      throw StateError('Supabase nao configurado.');
    }

    final empty = LevelUpState.empty();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final today = DateTime(now.year, now.month, now.day);

    final metasRows = await _client
        .from('metas')
        .select()
        .order('created_at', ascending: false)
        .limit(1);
    final vendasRows = await _client
        .from('vendas')
        .select()
        .gte('sale_date', _dateOnly(monthStart))
        .order('sale_date', ascending: false);
    final desafiosRows = await _client
        .from('desafios')
        .select()
        .order('created_at', ascending: false)
        .limit(200);

    final metas = metasRows.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(metasRows.first);
    final challenges = _parseChallenges(desafiosRows);

    var dailyIndividualSale = 0.0;
    var dailyStoreSale = 0.0;
    var weeklyIndividualSales = 0.0;
    var monthlyIndividualSales = 0.0;
    var weeklyStoreSales = 0.0;
    var monthlyStoreSales = 0.0;

    for (final row in vendasRows.map(Map<String, dynamic>.from)) {
      final saleDate = _parseDate(row['sale_date']);
      final individual = _toDouble(row['daily_individual_sale']);
      final store = _toDouble(row['daily_store_sale']);

      monthlyIndividualSales += individual;
      monthlyStoreSales += store;

      if (!saleDate.isBefore(weekStart)) {
        weeklyIndividualSales += individual;
        weeklyStoreSales += store;
      }

      if (_isSameDay(saleDate, today)) {
        dailyIndividualSale += individual;
        dailyStoreSale += store;
      }
    }

    return empty.copyWith(
      monthlyIndividualGoal: _toDouble(
        metas['monthly_individual_goal'],
        empty.monthlyIndividualGoal,
      ),
      weeklyIndividualGoal: _toDouble(
        metas['weekly_individual_goal'],
        empty.weeklyIndividualGoal,
      ),
      monthlyStoreGoal: _toDouble(
        metas['monthly_store_goal'],
        empty.monthlyStoreGoal,
      ),
      weeklyStoreGoal: _toDouble(
        metas['weekly_store_goal'],
        empty.weeklyStoreGoal,
      ),
      dailyIndividualSale: dailyIndividualSale,
      dailyStoreSale: dailyStoreSale,
      weeklyIndividualSales: weeklyIndividualSales,
      monthlyIndividualSales: monthlyIndividualSales,
      weeklyStoreSales: weeklyStoreSales,
      monthlyStoreSales: monthlyStoreSales,
      storeGoalChallenge: _toInt(null, empty.storeGoalChallenge),
      paChallenge: _toInt(null, empty.paChallenge),
      biggestTicketChallenge: _toInt(null, empty.biggestTicketChallenge),
      challenges: challenges,
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

  String _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }

  DateTime _parseDate(Object? value) {
    if (value == null) return DateTime(1900);
    return DateTime.tryParse(value.toString()) ?? DateTime(1900);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double _toDouble(Object? value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _toInt(Object? value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
