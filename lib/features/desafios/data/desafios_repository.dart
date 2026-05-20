import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../domain/challenge_entry.dart';

final desafiosRepositoryProvider = Provider<DesafiosRepository>((ref) {
  return DesafiosRepository(ref.watch(supabaseClientProvider));
});

class DesafiosRepository {
  const DesafiosRepository(this._client);

  final SupabaseClient? _client;

  Future<List<ChallengeEntry>> fetchChallenges() async {
    if (_client == null) return const [];

    final rows = await _client
        .from('desafios')
        .select()
        .order('created_at', ascending: false)
        .limit(200);

    return _parseRows(rows);
  }

  Future<void> saveChallenge({
    required ChallengeType type,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    if (_client == null) return;

    await _client
        .from('desafios')
        .insert(
          ChallengeEntry(
            date: date,
            type: type,
            amount: amount,
            notes: notes,
          ).toSupabase(),
        );
  }

  List<ChallengeEntry> _parseRows(List<dynamic> rows) {
    final entries = <ChallengeEntry>[];

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      if (row.containsKey('challenge_type')) {
        entries.add(ChallengeEntry.fromSupabase(row));
        continue;
      }
      entries.addAll(ChallengeEntry.legacyFromSupabase(row));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
}
