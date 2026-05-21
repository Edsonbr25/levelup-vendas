import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../domain/sale_entry.dart';

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

  Future<List<SaleEntry>> listSales({int limit = 60}) async {
    if (_client == null) return const [];

    final rows = await _client
        .from('vendas')
        .select()
        .order('sale_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .map((row) => SaleEntry.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createSale(SaleEntry sale) async {
    if (_client == null) return;

    await _client.from('vendas').insert({
      ...sale.toSupabase(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateSale(SaleEntry sale) async {
    if (_client == null || sale.id == null) return;

    await _client.from('vendas').update(sale.toSupabase()).eq('id', sale.id!);
  }

  Future<void> deleteSale(String id) async {
    if (_client == null) return;

    await _client.from('vendas').delete().eq('id', id);
  }

  Future<void> saveDailySales({
    required double dailyIndividualSale,
    required double dailyStoreSale,
    DateTime? saleDate,
  }) async {
    await createSale(
      SaleEntry(
        date: saleDate ?? DateTime.now(),
        individualSale: dailyIndividualSale,
        storeSale: dailyStoreSale,
      ),
    );
  }

  String _dateOnly(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
