import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../domain/seller.dart';
import '../domain/team_challenge.dart';
import '../domain/team_goal.dart';
import '../domain/team_sale.dart';
import '../domain/team_state.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository(ref.watch(supabaseClientProvider));
});

class TeamRepository {
  const TeamRepository(this._client);

  final SupabaseClient? _client;

  Future<TeamState> fetchState({DateTime? start, DateTime? end}) async {
    if (_client == null) {
      throw StateError('Supabase nao configurado.');
    }

    final now = DateTime.now();
    final periodStart = start ?? DateTime(now.year, now.month);
    final periodEnd =
        end ??
        DateTime(now.year, now.month + 1).subtract(const Duration(days: 1));

    final sellerRows = await _client.from('vendedores').select().order('name');
    final salesRows = await _client
        .from('sales')
        .select()
        .gte('sale_date', _dateOnly(periodStart))
        .lte('sale_date', _dateOnly(periodEnd))
        .order('sale_date', ascending: false);
    final goalRows = await _client
        .from('goals')
        .select()
        .lte('period_start', _dateOnly(periodEnd))
        .order('created_at', ascending: false);
    final challengeRows = await _client
        .from('challenge_records')
        .select()
        .gte('challenge_date', _dateOnly(periodStart))
        .lte('challenge_date', _dateOnly(periodEnd))
        .order('challenge_date', ascending: false);

    return TeamState(
      sellers: [for (final row in sellerRows) Seller.fromSupabase(_map(row))],
      sales: [for (final row in salesRows) TeamSale.fromSupabase(_map(row))],
      goals: [for (final row in goalRows) TeamGoal.fromSupabase(_map(row))],
      challenges: [
        for (final row in challengeRows) TeamChallenge.fromSupabase(_map(row)),
      ],
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  Future<void> createSeller(Seller seller) async {
    if (_client == null) return;
    await _client.from('vendedores').insert(seller.toSupabase());
  }

  Future<void> createSale(TeamSale sale) async {
    if (_client == null) return;
    await _client.from('sales').insert({
      ...sale.toSupabase(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateSale(TeamSale sale) async {
    if (_client == null || sale.id == null) return;
    await _client.from('sales').update(sale.toSupabase()).eq('id', sale.id!);
  }

  Future<void> deleteSale(String id) async {
    if (_client == null) return;
    await _client.from('sales').delete().eq('id', id);
  }

  Future<void> saveGoal(TeamGoal goal) async {
    if (_client == null) return;
    await _client.from('goals').insert({
      ...goal.toSupabase(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> createChallenge(TeamChallenge challenge) async {
    if (_client == null) return;
    await _client.from('challenge_records').insert({
      ...challenge.toSupabase(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateChallenge(TeamChallenge challenge) async {
    if (_client == null || challenge.id == null) return;
    await _client
        .from('challenge_records')
        .update(challenge.toSupabase())
        .eq('id', challenge.id!);
  }

  Future<void> deleteChallenge(String id) async {
    if (_client == null) return;
    await _client.from('challenge_records').delete().eq('id', id);
  }

  Map<String, dynamic> _map(Object? raw) {
    return Map<String, dynamic>.from(raw as Map);
  }

  String _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }
}
