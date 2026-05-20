import '../../../core/constants/app_constants.dart';
import '../../desafios/domain/challenge_entry.dart';

class LevelUpState {
  const LevelUpState({
    required this.monthlyIndividualGoal,
    required this.weeklyIndividualGoal,
    required this.monthlyStoreGoal,
    required this.weeklyStoreGoal,
    required this.weeklyStartDate,
    required this.weeklyEndDate,
    required this.dailyIndividualSale,
    required this.dailyStoreSale,
    required this.weeklyIndividualSales,
    required this.monthlyIndividualSales,
    required this.weeklyStoreSales,
    required this.monthlyStoreSales,
    required this.storeGoalChallenge,
    required this.paChallenge,
    required this.biggestTicketChallenge,
    required this.challenges,
    this.isFallback = false,
    this.errorMessage,
  });

  factory LevelUpState.initialMock() {
    return LevelUpState(
      monthlyIndividualGoal: 85000,
      weeklyIndividualGoal: 21250,
      monthlyStoreGoal: 420000,
      weeklyStoreGoal: 105000,
      weeklyStartDate: DateTime(2026, 5, 18),
      weeklyEndDate: DateTime(2026, 5, 24),
      dailyIndividualSale: 4200,
      dailyStoreSale: 18600,
      weeklyIndividualSales: 4200 * 5,
      monthlyIndividualSales: 4200 * 22,
      weeklyStoreSales: 18600 * 5,
      monthlyStoreSales: 18600 * 22,
      storeGoalChallenge: 1,
      paChallenge: 2,
      biggestTicketChallenge: 1,
      challenges: [
        ChallengeEntry(
          date: DateTime(2026, 5, 2),
          type: ChallengeType.storeGoal,
          amount: 120,
          notes: 'Meta loja batida',
        ),
        ChallengeEntry(
          date: DateTime(2026, 5, 8),
          type: ChallengeType.pa,
          amount: 70,
        ),
        ChallengeEntry(
          date: DateTime(2026, 5, 13),
          type: ChallengeType.biggestTicket,
          amount: 90,
        ),
      ],
    );
  }

  factory LevelUpState.empty() {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return LevelUpState(
      monthlyIndividualGoal: 0,
      weeklyIndividualGoal: 0,
      monthlyStoreGoal: 0,
      weeklyStoreGoal: 0,
      weeklyStartDate: weekStart,
      weeklyEndDate: weekStart.add(const Duration(days: 6)),
      dailyIndividualSale: 0,
      dailyStoreSale: 0,
      weeklyIndividualSales: 0,
      monthlyIndividualSales: 0,
      weeklyStoreSales: 0,
      monthlyStoreSales: 0,
      storeGoalChallenge: 0,
      paChallenge: 0,
      biggestTicketChallenge: 0,
      challenges: [],
    );
  }

  final double monthlyIndividualGoal;
  final double weeklyIndividualGoal;
  final double monthlyStoreGoal;
  final double weeklyStoreGoal;
  final DateTime weeklyStartDate;
  final DateTime weeklyEndDate;
  final double dailyIndividualSale;
  final double dailyStoreSale;
  final double weeklyIndividualSales;
  final double monthlyIndividualSales;
  final double weeklyStoreSales;
  final double monthlyStoreSales;
  final int storeGoalChallenge;
  final int paChallenge;
  final int biggestTicketChallenge;
  final List<ChallengeEntry> challenges;
  final bool isFallback;
  final String? errorMessage;

  int get weeklyPeriodDays {
    final start = _dateOnly(weeklyStartDate);
    final end = _dateOnly(weeklyEndDate);
    if (end.isBefore(start)) return 1;
    return end.difference(start).inDays + 1;
  }

  double get dailyIndividualGoal => weeklyIndividualGoal / weeklyPeriodDays;
  double get dailyStoreGoal => weeklyStoreGoal / weeklyPeriodDays;
  String get weeklyPeriodLabel =>
      '${_shortDate(weeklyStartDate)} a ${_shortDate(weeklyEndDate)}';
  double get dailyIndividualPercent =>
      _ratio(dailyIndividualSale, dailyIndividualGoal);
  double get dailyStorePercent => _ratio(dailyStoreSale, dailyStoreGoal);
  double get weeklyIndividualPercent =>
      _ratio(weeklyIndividualSales, weeklyIndividualGoal);
  double get monthlyIndividualPercent =>
      _ratio(monthlyIndividualSales, monthlyIndividualGoal);
  double get weeklyStorePercent => _ratio(weeklyStoreSales, weeklyStoreGoal);
  double get monthlyStorePercent => _ratio(monthlyStoreSales, monthlyStoreGoal);

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
        monthlyIndividualSales * (individualCommissionRate / 100);
    final store = monthlyStoreSales * (storeCommissionRate / 100);
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
        (storeGoalChallengeCount * 50) +
        (paChallengeCount * 25) +
        (biggestTicketChallengeCount * 40);
    return dailyXp + storeXp + challengeXp;
  }

  int get storeGoalChallengeCount =>
      _challengeCount(ChallengeType.storeGoal, storeGoalChallenge);

  int get paChallengeCount => _challengeCount(ChallengeType.pa, paChallenge);

  int get biggestTicketChallengeCount =>
      _challengeCount(ChallengeType.biggestTicket, biggestTicketChallenge);

  double get monthlyChallengeTotal => _challengeAmountForMonth(null);

  double get monthlyStoreGoalChallengeTotal =>
      _challengeAmountForMonth(ChallengeType.storeGoal);

  double get monthlyPaChallengeTotal =>
      _challengeAmountForMonth(ChallengeType.pa);

  double get monthlyBiggestTicketChallengeTotal =>
      _challengeAmountForMonth(ChallengeType.biggestTicket);

  double get storeGoalChallengeTotal =>
      _challengeAmount(ChallengeType.storeGoal, currentMonthOnly: false);

  double get paChallengeTotal =>
      _challengeAmount(ChallengeType.pa, currentMonthOnly: false);

  double get biggestTicketChallengeTotal =>
      _challengeAmount(ChallengeType.biggestTicket, currentMonthOnly: false);

  Map<ChallengeType, double> get monthlyChallengeTotalsByType => {
    ChallengeType.storeGoal: monthlyStoreGoalChallengeTotal,
    ChallengeType.pa: monthlyPaChallengeTotal,
    ChallengeType.biggestTicket: monthlyBiggestTicketChallengeTotal,
  };

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

  int get nextLevelTarget {
    return switch (xp) {
      >= 500 => 500,
      >= 300 => 500,
      >= 180 => 300,
      >= 80 => 180,
      _ => 80,
    };
  }

  String get nextLevel {
    return switch (xp) {
      >= 500 => 'Maximo',
      >= 300 => 'Lenda',
      >= 180 => 'Diamante',
      >= 80 => 'Ouro',
      _ => 'Prata',
    };
  }

  int get xpToNextLevel => (nextLevelTarget - xp).clamp(0, nextLevelTarget);

  int get goalStreak {
    var streak = 0;
    if (dailyIndividualSale >= dailyIndividualGoal && dailyIndividualGoal > 0) {
      streak++;
    }
    if (dailyStoreSale >= dailyStoreGoal && dailyStoreGoal > 0) {
      streak++;
    }
    if (weeklyIndividualPercent >= 100) streak++;
    if (weeklyStorePercent >= 100) streak++;
    return streak;
  }

  List<double> get weeklyIndividualChart => _series(
    total: weeklyIndividualSales,
    current: dailyIndividualSale,
    points: 7,
  );

  List<double> get weeklyStoreChart =>
      _series(total: weeklyStoreSales, current: dailyStoreSale, points: 7);

  List<double> get monthlyIndividualChart => _series(
    total: monthlyIndividualSales,
    current: dailyIndividualSale,
    points: 6,
  );

  List<double> get monthlyStoreChart =>
      _series(total: monthlyStoreSales, current: dailyStoreSale, points: 6);

  LevelUpState copyWith({
    double? monthlyIndividualGoal,
    double? weeklyIndividualGoal,
    double? monthlyStoreGoal,
    double? weeklyStoreGoal,
    DateTime? weeklyStartDate,
    DateTime? weeklyEndDate,
    double? dailyIndividualSale,
    double? dailyStoreSale,
    double? weeklyIndividualSales,
    double? monthlyIndividualSales,
    double? weeklyStoreSales,
    double? monthlyStoreSales,
    int? storeGoalChallenge,
    int? paChallenge,
    int? biggestTicketChallenge,
    List<ChallengeEntry>? challenges,
    bool? isFallback,
    String? errorMessage,
  }) {
    return LevelUpState(
      monthlyIndividualGoal:
          monthlyIndividualGoal ?? this.monthlyIndividualGoal,
      weeklyIndividualGoal: weeklyIndividualGoal ?? this.weeklyIndividualGoal,
      monthlyStoreGoal: monthlyStoreGoal ?? this.monthlyStoreGoal,
      weeklyStoreGoal: weeklyStoreGoal ?? this.weeklyStoreGoal,
      weeklyStartDate: weeklyStartDate ?? this.weeklyStartDate,
      weeklyEndDate: weeklyEndDate ?? this.weeklyEndDate,
      dailyIndividualSale: dailyIndividualSale ?? this.dailyIndividualSale,
      dailyStoreSale: dailyStoreSale ?? this.dailyStoreSale,
      weeklyIndividualSales:
          weeklyIndividualSales ?? this.weeklyIndividualSales,
      monthlyIndividualSales:
          monthlyIndividualSales ?? this.monthlyIndividualSales,
      weeklyStoreSales: weeklyStoreSales ?? this.weeklyStoreSales,
      monthlyStoreSales: monthlyStoreSales ?? this.monthlyStoreSales,
      storeGoalChallenge: storeGoalChallenge ?? this.storeGoalChallenge,
      paChallenge: paChallenge ?? this.paChallenge,
      biggestTicketChallenge:
          biggestTicketChallenge ?? this.biggestTicketChallenge,
      challenges: challenges ?? this.challenges,
      isFallback: isFallback ?? this.isFallback,
      errorMessage: errorMessage,
    );
  }

  static double _ratio(double value, double target) {
    if (target <= 0) return 0;
    return (value / target) * 100;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static List<double> _series({
    required double total,
    required double current,
    required int points,
  }) {
    if (points <= 0) return const [];
    if (total <= 0) return List<double>.filled(points, 0);

    final weights = List<double>.generate(
      points,
      (index) => 0.76 + (index * 0.08) + (index.isEven ? 0.09 : -0.03),
    );
    final weightTotal = weights.reduce((value, item) => value + item);
    final generated = [
      for (final weight in weights) total * (weight / weightTotal),
    ];
    generated[generated.length - 1] = current > 0 ? current : generated.last;
    return generated;
  }

  int _challengeCount(ChallengeType type, int legacyFallback) {
    final count = challenges.where((entry) => entry.type == type).length;
    return count == 0 ? legacyFallback : count;
  }

  double _challengeAmountForMonth(ChallengeType? type) {
    return challenges
        .where((entry) => type == null || entry.type == type)
        .where(_isCurrentMonth)
        .fold(0, (total, entry) => total + entry.amount);
  }

  double _challengeAmount(
    ChallengeType type, {
    required bool currentMonthOnly,
  }) {
    return challenges
        .where((entry) => entry.type == type)
        .where((entry) => !currentMonthOnly || _isCurrentMonth(entry))
        .fold(0, (total, entry) => total + entry.amount);
  }

  bool _isCurrentMonth(ChallengeEntry entry) {
    final now = DateTime.now();
    return entry.date.year == now.year && entry.date.month == now.month;
  }
}
