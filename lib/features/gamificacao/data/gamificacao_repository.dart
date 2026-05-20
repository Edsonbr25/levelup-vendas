import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

final gamificacaoRepositoryProvider = Provider<GamificacaoRepository>((ref) {
  return GamificacaoRepository(ref.watch(supabaseClientProvider));
});

class GamificacaoRepository {
  const GamificacaoRepository(this._client);

  final SupabaseClient? _client;

  Future<void> saveProgress({required int xp, required String level}) async {
    if (_client == null) return;

    await _client.from('gamificacao').insert({
      'xp': xp,
      'level': level,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
