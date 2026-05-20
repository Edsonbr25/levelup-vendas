import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

final metasRepositoryProvider = Provider<MetasRepository>((ref) {
  return MetasRepository(ref.watch(supabaseClientProvider));
});

class MetasRepository {
  const MetasRepository(this._client);

  final SupabaseClient? _client;

  Future<Map<String, dynamic>?> fetchLatestGoals() async {
    if (_client == null) return null;

    final rows = await _client
        .from('metas')
        .select()
        .order('created_at', ascending: false)
        .limit(1);

    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveGoals({
    required double monthlyIndividualGoal,
    required double weeklyIndividualGoal,
    required double monthlyStoreGoal,
    required double weeklyStoreGoal,
    required DateTime weeklyStartDate,
    required DateTime weeklyEndDate,
  }) async {
    if (_client == null) return;

    await _client.from('metas').insert({
      'monthly_individual_goal': monthlyIndividualGoal,
      'weekly_individual_goal': weeklyIndividualGoal,
      'monthly_store_goal': monthlyStoreGoal,
      'weekly_store_goal': weeklyStoreGoal,
      'weekly_start_date': _dateOnly(weeklyStartDate),
      'weekly_end_date': _dateOnly(weeklyEndDate),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }
}
