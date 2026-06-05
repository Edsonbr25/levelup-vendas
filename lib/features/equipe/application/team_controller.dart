import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/team_repository.dart';
import '../domain/seller.dart';
import '../domain/team_challenge.dart';
import '../domain/team_goal.dart';
import '../domain/team_sale.dart';
import '../domain/team_state.dart';

final teamProvider = AsyncNotifierProvider<TeamController, TeamState>(
  TeamController.new,
);

class TeamController extends AsyncNotifier<TeamState> {
  DateTime? _periodStart;
  DateTime? _periodEnd;

  @override
  Future<TeamState> build() async {
    return _load();
  }

  Future<void> setPeriod(DateTime start, DateTime end) async {
    _periodStart = start;
    _periodEnd = end;
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> createSeller(Seller seller) async {
    await _mutate(() => ref.read(teamRepositoryProvider).createSeller(seller));
  }

  Future<void> createSale(TeamSale sale) async {
    await _mutate(() => ref.read(teamRepositoryProvider).createSale(sale));
  }

  Future<void> updateSale(TeamSale sale) async {
    await _mutate(() => ref.read(teamRepositoryProvider).updateSale(sale));
  }

  Future<void> deleteSale(TeamSale sale) async {
    if (sale.id == null) return;
    await _mutate(() => ref.read(teamRepositoryProvider).deleteSale(sale.id!));
  }

  Future<void> saveGoal(TeamGoal goal) async {
    await _mutate(() => ref.read(teamRepositoryProvider).saveGoal(goal));
  }

  Future<void> createChallenge(TeamChallenge challenge) async {
    await _mutate(
      () => ref.read(teamRepositoryProvider).createChallenge(challenge),
    );
  }

  Future<void> updateChallenge(TeamChallenge challenge) async {
    await _mutate(
      () => ref.read(teamRepositoryProvider).updateChallenge(challenge),
    );
  }

  Future<void> deleteChallenge(TeamChallenge challenge) async {
    if (challenge.id == null) return;
    await _mutate(
      () => ref.read(teamRepositoryProvider).deleteChallenge(challenge.id!),
    );
  }

  Future<void> _mutate(Future<void> Function() operation) async {
    final previous = state.value ?? TeamState.mock();
    state = const AsyncLoading();
    try {
      await operation();
      state = AsyncData(await _load());
    } catch (error) {
      debugPrint('Team fallback after mutation error: $error');
      state = AsyncData(
        previous.copyFallback('Operacao local temporaria: $error'),
      );
    }
  }

  Future<TeamState> _load() async {
    try {
      return await ref
          .read(teamRepositoryProvider)
          .fetchState(start: _periodStart, end: _periodEnd);
    } catch (error) {
      debugPrint('Team fallback after load error: $error');
      return TeamState.mock().copyFallback(error.toString());
    }
  }
}

extension on TeamState {
  TeamState copyFallback(String message) {
    return TeamState(
      sellers: sellers,
      sales: sales,
      goals: goals,
      challenges: challenges,
      periodStart: periodStart,
      periodEnd: periodEnd,
      isFallback: true,
      errorMessage: message,
    );
  }
}
