import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desafios/data/desafios_repository.dart';
import '../../desafios/domain/challenge_entry.dart';
import '../../metas/data/metas_repository.dart';
import '../../vendas/data/vendas_repository.dart';
import '../../vendas/domain/sale_entry.dart';
import '../data/gamificacao_repository.dart';
import '../data/level_up_repository.dart';
import '../domain/level_up_state.dart';

final levelUpProvider = AsyncNotifierProvider<LevelUpController, LevelUpState>(
  LevelUpController.new,
);

class LevelUpController extends AsyncNotifier<LevelUpState> {
  @override
  Future<LevelUpState> build() async {
    return _loadWithFallback();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadWithFallback);
  }

  Future<void> updateGoals({
    required double monthlyIndividualGoal,
    required double weeklyIndividualGoal,
    required double monthlyStoreGoal,
    required double weeklyStoreGoal,
    required DateTime weeklyStartDate,
    required DateTime weeklyEndDate,
  }) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      await ref
          .read(metasRepositoryProvider)
          .saveGoals(
            monthlyIndividualGoal: monthlyIndividualGoal,
            weeklyIndividualGoal: weeklyIndividualGoal,
            monthlyStoreGoal: monthlyStoreGoal,
            weeklyStoreGoal: weeklyStoreGoal,
            weeklyStartDate: weeklyStartDate,
            weeklyEndDate: weeklyEndDate,
          );

      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        previous.copyWith(
          monthlyIndividualGoal: monthlyIndividualGoal,
          weeklyIndividualGoal: weeklyIndividualGoal,
          monthlyStoreGoal: monthlyStoreGoal,
          weeklyStoreGoal: weeklyStoreGoal,
          weeklyStartDate: weeklyStartDate,
          weeklyEndDate: weeklyEndDate,
          isFallback: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updateSales({
    required double dailyIndividualSale,
    required double dailyStoreSale,
    DateTime? saleDate,
  }) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      await ref
          .read(vendasRepositoryProvider)
          .saveDailySales(
            dailyIndividualSale: dailyIndividualSale,
            dailyStoreSale: dailyStoreSale,
            saleDate: saleDate,
          );

      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        previous.copyWith(
          dailyIndividualSale: dailyIndividualSale,
          dailyStoreSale: dailyStoreSale,
          weeklyIndividualSales:
              previous.weeklyIndividualSales + dailyIndividualSale,
          monthlyIndividualSales:
              previous.monthlyIndividualSales + dailyIndividualSale,
          weeklyStoreSales: previous.weeklyStoreSales + dailyStoreSale,
          monthlyStoreSales: previous.monthlyStoreSales + dailyStoreSale,
          isFallback: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> createSale(SaleEntry sale) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      await ref.read(vendasRepositoryProvider).createSale(sale);
      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        _applySaleFallback(
          previous,
          sale,
        ).copyWith(isFallback: true, errorMessage: error.toString()),
      );
    }
  }

  Future<void> updateSale(SaleEntry sale) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      await ref.read(vendasRepositoryProvider).updateSale(sale);
      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        previous.copyWith(isFallback: true, errorMessage: error.toString()),
      );
    }
  }

  Future<void> deleteSale(SaleEntry sale) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      if (sale.id != null) {
        await ref.read(vendasRepositoryProvider).deleteSale(sale.id!);
      }
      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        previous.copyWith(isFallback: true, errorMessage: error.toString()),
      );
    }
  }

  Future<void> addChallenge({
    required ChallengeType type,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      await ref
          .read(desafiosRepositoryProvider)
          .saveChallenge(type: type, amount: amount, date: date, notes: notes);

      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        previous.copyWith(
          challenges: [
            ChallengeEntry(
              date: date,
              type: type,
              amount: amount,
              notes: notes,
            ),
            ...previous.challenges,
          ],
          isFallback: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updateChallenge(ChallengeEntry entry) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      await ref.read(desafiosRepositoryProvider).updateChallenge(entry);
      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        previous.copyWith(
          challenges: [
            for (final item in previous.challenges)
              if (item.id == entry.id) entry else item,
          ],
          isFallback: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteChallenge(ChallengeEntry entry) async {
    final previous = state.value ?? LevelUpState.initialMock();
    state = const AsyncLoading();

    try {
      if (entry.id != null) {
        await ref.read(desafiosRepositoryProvider).deleteChallenge(entry.id!);
      }
      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      state = AsyncData(fresh);
    } catch (error) {
      state = AsyncData(
        previous.copyWith(
          challenges: [
            for (final item in previous.challenges)
              if (item != entry) item,
          ],
          isFallback: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<LevelUpState> _loadWithFallback() async {
    try {
      final fresh = await ref
          .read(levelUpRepositoryProvider)
          .fetchDashboardState();
      await _saveGamification(fresh);
      return fresh;
    } catch (error) {
      debugPrint('LevelUp fallback after load error: $error');
      return LevelUpState.initialMock().copyWith(
        isFallback: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> _saveGamification(LevelUpState state) async {
    await ref
        .read(gamificacaoRepositoryProvider)
        .saveProgress(xp: state.xp, level: state.level);
  }

  LevelUpState _applySaleFallback(LevelUpState previous, SaleEntry sale) {
    final today = DateTime.now();
    final saleDate = DateTime(sale.date.year, sale.date.month, sale.date.day);
    final currentMonth =
        saleDate.year == today.year && saleDate.month == today.month;
    final inWeek =
        !saleDate.isBefore(previous.weeklyStartDate) &&
        !saleDate.isAfter(previous.weeklyEndDate);
    final isToday =
        saleDate.year == today.year &&
        saleDate.month == today.month &&
        saleDate.day == today.day;

    return previous.copyWith(
      dailyIndividualSale: isToday
          ? previous.dailyIndividualSale + sale.individualSale
          : previous.dailyIndividualSale,
      dailyStoreSale: isToday
          ? previous.dailyStoreSale + sale.storeSale
          : previous.dailyStoreSale,
      weeklyIndividualSales: inWeek
          ? previous.weeklyIndividualSales + sale.individualSale
          : previous.weeklyIndividualSales,
      weeklyStoreSales: inWeek
          ? previous.weeklyStoreSales + sale.storeSale
          : previous.weeklyStoreSales,
      monthlyIndividualSales: currentMonth
          ? previous.monthlyIndividualSales + sale.individualSale
          : previous.monthlyIndividualSales,
      monthlyStoreSales: currentMonth
          ? previous.monthlyStoreSales + sale.storeSale
          : previous.monthlyStoreSales,
    );
  }
}
