import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

final levelUpProvider = NotifierProvider<LevelUpController, LevelUpState>(
  LevelUpController.new,
);

class LevelUpState {
  const LevelUpState({
    required this.monthlyIndividualGoal,
    required this.weeklyIndividualGoal,
    required this.monthlyStoreGoal,
    required this.weeklyStoreGoal,
    required this.dailyIndividualSale,
    required this.dailyStoreSale,
    required this.storeGoalChallenge,
    required this.paChallenge,
    required this.biggestTicketChallenge,
  });

  factory LevelUpState.mock() {
    return const LevelUpState(
      monthlyIndividualGoal: 85000,
      weeklyIndividualGoal: 21250,
      monthlyStoreGoal: 420000,
      weeklyStoreGoal: 105000,
      dailyIndividualSale: 4200,
      dailyStoreSale: 18600,
      storeGoalChallenge: 1,
      paChallenge: 2,
      biggestTicketChallenge: 1,
    );
  }

  final double monthlyIndividualGoal;
  final double weeklyIndividualGoal;
  final double monthlyStoreGoal;
  final double weeklyStoreGoal;
  final double dailyIndividualSale;
  final double dailyStoreSale;
  final int storeGoalChallenge;
  final int paChallenge;
  final int biggestTicketChallenge;

  double get dailyIndividualGoal => monthlyIndividualGoal / 22;
  double get dailyStoreGoal => monthlyStoreGoal / 22;
  double get weeklyIndividualPercent =>
      _ratio(dailyIndividualSale * 5, weeklyIndividualGoal);
  double get monthlyIndividualPercent =>
      _ratio(dailyIndividualSale * 22, monthlyIndividualGoal);
  double get weeklyStorePercent => _ratio(dailyStoreSale * 5, weeklyStoreGoal);
  double get monthlyStorePercent =>
      _ratio(dailyStoreSale * 22, monthlyStoreGoal);

  double get individualCommissionRate {
    final reached = monthlyIndividualPercent;
    if (reached >= 120) return 6;
    if (reached >= 100) return 5;
    if (reached >= 90) return 3;
    return 0;
  }

  double get storeCommissionRate {
    final reached = monthlyStorePercent;
    if (reached >= 120) return 3;
    if (reached >= 100) return 2;
    if (reached >= 95) return 0.5;
    return 0;
  }

  double get estimatedCommission {
    final individual =
        dailyIndividualSale * 22 * (individualCommissionRate / 100);
    final store = dailyStoreSale * 22 * (storeCommissionRate / 100);
    return individual + store;
  }

  int get xp {
    final dailyXp = dailyIndividualSale >= dailyIndividualGoal
        ? AppConstants.dailyIndividualXp
        : 0;
    final storeXp = dailyStoreSale >= dailyStoreGoal
        ? AppConstants.dailyStoreXp
        : 0;
    final challengeXp =
        (storeGoalChallenge * 50) +
        (paChallenge * 25) +
        (biggestTicketChallenge * 40);
    return dailyXp + storeXp + challengeXp;
  }

  String get level {
    if (xp >= 500) return 'Lenda';
    if (xp >= 300) return 'Diamante';
    if (xp >= 180) return 'Ouro';
    if (xp >= 80) return 'Prata';
    return 'Bronze';
  }

  double get nextLevelProgress {
    final currentXp = xp;
    final target = switch (currentXp) {
      >= 500 => 500,
      >= 300 => 500,
      >= 180 => 300,
      >= 80 => 180,
      _ => 80,
    };
    return (currentXp / target).clamp(0, 1).toDouble();
  }

  LevelUpState copyWith({
    double? monthlyIndividualGoal,
    double? weeklyIndividualGoal,
    double? monthlyStoreGoal,
    double? weeklyStoreGoal,
    double? dailyIndividualSale,
    double? dailyStoreSale,
    int? storeGoalChallenge,
    int? paChallenge,
    int? biggestTicketChallenge,
  }) {
    return LevelUpState(
      monthlyIndividualGoal:
          monthlyIndividualGoal ?? this.monthlyIndividualGoal,
      weeklyIndividualGoal: weeklyIndividualGoal ?? this.weeklyIndividualGoal,
      monthlyStoreGoal: monthlyStoreGoal ?? this.monthlyStoreGoal,
      weeklyStoreGoal: weeklyStoreGoal ?? this.weeklyStoreGoal,
      dailyIndividualSale: dailyIndividualSale ?? this.dailyIndividualSale,
      dailyStoreSale: dailyStoreSale ?? this.dailyStoreSale,
      storeGoalChallenge: storeGoalChallenge ?? this.storeGoalChallenge,
      paChallenge: paChallenge ?? this.paChallenge,
      biggestTicketChallenge:
          biggestTicketChallenge ?? this.biggestTicketChallenge,
    );
  }

  static double _ratio(double value, double target) {
    if (target <= 0) return 0;
    return (value / target) * 100;
  }
}

class LevelUpController extends Notifier<LevelUpState> {
  @override
  LevelUpState build() => LevelUpState.mock();

  void updateGoals({
    required double monthlyIndividualGoal,
    required double weeklyIndividualGoal,
    required double monthlyStoreGoal,
    required double weeklyStoreGoal,
  }) {
    state = state.copyWith(
      monthlyIndividualGoal: monthlyIndividualGoal,
      weeklyIndividualGoal: weeklyIndividualGoal,
      monthlyStoreGoal: monthlyStoreGoal,
      weeklyStoreGoal: weeklyStoreGoal,
    );
  }

  void updateSales({
    required double dailyIndividualSale,
    required double dailyStoreSale,
  }) {
    state = state.copyWith(
      dailyIndividualSale: dailyIndividualSale,
      dailyStoreSale: dailyStoreSale,
    );
  }

  void updateChallenges({
    required int storeGoalChallenge,
    required int paChallenge,
    required int biggestTicketChallenge,
  }) {
    state = state.copyWith(
      storeGoalChallenge: storeGoalChallenge,
      paChallenge: paChallenge,
      biggestTicketChallenge: biggestTicketChallenge,
    );
  }
}
