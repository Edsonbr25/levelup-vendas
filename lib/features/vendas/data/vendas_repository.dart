import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

final vendasRepositoryProvider = Provider<VendasRepository>((ref) {
  return VendasRepository(ref.watch(supabaseClientProvider));
});

class VendasRepository {
  const VendasRepository(this._client);

  final SupabaseClient? _client;

  Future<List<Map<String, dynamic>>> fetchSalesSince(DateTime start) async {
    if (_client == null) return const [];

    final rows = await _client
        .from('vendas')
        .select()
        .gte('sale_date', _dateOnly(start))
        .order('sale_date', ascending: false);

    return rows.map(Map<String, dynamic>.from).toList();
  }

  Future<void> saveDailySales({
    required double dailyIndividualSale,
    required double dailyStoreSale,
  }) async {
    if (_client == null) return;

    await _client.from('vendas').insert({
      'sale_date': _dateOnly(DateTime.now()),
      'daily_individual_sale': dailyIndividualSale,
      'daily_store_sale': dailyStoreSale,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String _dateOnly(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
