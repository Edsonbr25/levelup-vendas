import '../../desafios/domain/challenge_entry.dart';

class HistoricalReport {
  const HistoricalReport({
    required this.period,
    required this.monthlyIndividualGoal,
    required this.weeklyIndividualGoal,
    required this.monthlyStoreGoal,
    required this.weeklyStoreGoal,
    required this.weeklyStartDate,
    required this.weeklyEndDate,
    required this.individualSalesTotal,
    required this.storeSalesTotal,
    required this.challenges,
    required this.salesByDay,
    required this.isFallback,
    this.errorMessage,
  });

  factory HistoricalReport.fallback(HistoryPeriod period) {
    final days = DateTime(period.year, period.month + 1, 0).day;
    final salesByDay = {
      for (var day = 1; day <= days; day++)
        day: DaySales(
          individual: 2500 + (day % 5) * 420,
          store: 12000 + (day % 6) * 1450,
        ),
    };

    return HistoricalReport(
      period: period,
      monthlyIndividualGoal: 85000,
      weeklyIndividualGoal: 21250,
      monthlyStoreGoal: 420000,
      weeklyStoreGoal: 105000,
      weeklyStartDate: DateTime(period.year, period.month, 1),
      weeklyEndDate: DateTime(period.year, period.month, 7),
      individualSalesTotal: salesByDay.values.fold(
        0,
        (total, item) => total + item.individual,
      ),
      storeSalesTotal: salesByDay.values.fold(
        0,
        (total, item) => total + item.store,
      ),
      challenges: [
        ChallengeEntry(
          date: DateTime(period.year, period.month, 3),
          type: ChallengeType.storeGoal,
          amount: 120,
        ),
        ChallengeEntry(
          date: DateTime(period.year, period.month, 11),
          type: ChallengeType.pa,
          amount: 75,
        ),
        ChallengeEntry(
          date: DateTime(period.year, period.month, 20),
          type: ChallengeType.biggestTicket,
          amount: 100,
        ),
      ],
      salesByDay: salesByDay,
      isFallback: true,
      errorMessage: 'Usando dados locais temporarios.',
    );
  }

  final HistoryPeriod period;
  final double monthlyIndividualGoal;
  final double weeklyIndividualGoal;
  final double monthlyStoreGoal;
  final double weeklyStoreGoal;
  final DateTime weeklyStartDate;
  final DateTime weeklyEndDate;
  final double individualSalesTotal;
  final double storeSalesTotal;
  final List<ChallengeEntry> challenges;
  final Map<int, DaySales> salesByDay;
  final bool isFallback;
  final String? errorMessage;

  double get totalSales => individualSalesTotal + storeSalesTotal;

  double get individualPercent =>
      _ratio(individualSalesTotal, monthlyIndividualGoal);

  double get storePercent => _ratio(storeSalesTotal, monthlyStoreGoal);

  double get weeklyIndividualSalesTotal =>
      _weeklySalesTotal((sales) => sales.individual);

  double get weeklyStoreSalesTotal => _weeklySalesTotal((sales) => sales.store);

  double get weeklyIndividualPercent =>
      _ratio(weeklyIndividualSalesTotal, weeklyIndividualGoal);

  double get weeklyStorePercent =>
      _ratio(weeklyStoreSalesTotal, weeklyStoreGoal);

  int get weeklyPeriodDays {
    final start = _dateOnly(weeklyStartDate);
    final end = _dateOnly(weeklyEndDate);
    if (end.isBefore(start)) return 1;
    return end.difference(start).inDays + 1;
  }

  String get weeklyPeriodLabel =>
      '${_shortDate(weeklyStartDate)} a ${_shortDate(weeklyEndDate)}';

  double get individualCommissionRate {
    if (individualPercent >= 120) return 6;
    if (individualPercent >= 100) return 5;
    if (individualPercent >= 90) return 3;
    return 0;
  }

  double get storeCommissionRate {
    if (storePercent >= 120) return 3;
    if (storePercent >= 100) return 2;
    if (storePercent >= 95) return 0.5;
    return 0;
  }

  double get individualCommission =>
      individualSalesTotal * (individualCommissionRate / 100);

  double get storeCommission => storeSalesTotal * (storeCommissionRate / 100);

  double get estimatedCommission => individualCommission + storeCommission;

  double get challengeTotal =>
      challenges.fold(0, (total, item) => total + item.amount);

  double challengeTotalByType(ChallengeType type) {
    return challenges
        .where((entry) => entry.type == type)
        .fold(0, (total, item) => total + item.amount);
  }

  int get goalsReached {
    var total = 0;
    if (individualPercent >= 100) total++;
    if (storePercent >= 100) total++;
    if (weeklyIndividualPercent >= 100) total++;
    if (weeklyStorePercent >= 100) total++;
    return total;
  }

  int get streak {
    var best = 0;
    var current = 0;
    for (final day in salesByDay.keys.toList()..sort()) {
      final sales = salesByDay[day]!;
      final date = DateTime(period.year, period.month, day);
      final dailyIndividualGoal = _isInsideWeeklyPeriod(date)
          ? weeklyIndividualGoal / weeklyPeriodDays
          : monthlyIndividualGoal / period.daysInMonth;
      final dailyStoreGoal = _isInsideWeeklyPeriod(date)
          ? weeklyStoreGoal / weeklyPeriodDays
          : monthlyStoreGoal / period.daysInMonth;
      if (sales.individual >= dailyIndividualGoal ||
          sales.store >= dailyStoreGoal) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  int get xp {
    final salesXp = goalsReached * 120;
    final challengeXp = challenges.length * 35;
    final streakXp = streak * 10;
    return salesXp + challengeXp + streakXp;
  }

  String get level {
    if (xp >= 500) return 'Lenda';
    if (xp >= 300) return 'Diamante';
    if (xp >= 180) return 'Ouro';
    if (xp >= 80) return 'Prata';
    return 'Bronze';
  }

  List<double> get individualChart => [
    for (var day = 1; day <= period.daysInMonth; day++)
      salesByDay[day]?.individual ?? 0,
  ];

  List<double> get storeChart => [
    for (var day = 1; day <= period.daysInMonth; day++)
      salesByDay[day]?.store ?? 0,
  ];

  static double _ratio(double value, double target) {
    if (target <= 0) return 0;
    return (value / target) * 100;
  }

  double _weeklySalesTotal(double Function(DaySales sales) selector) {
    return salesByDay.entries
        .where((entry) {
          final date = DateTime(period.year, period.month, entry.key);
          return _isInsideWeeklyPeriod(date);
        })
        .fold(0, (total, entry) => total + selector(entry.value));
  }

  bool _isInsideWeeklyPeriod(DateTime value) {
    final date = _dateOnly(value);
    final start = _dateOnly(weeklyStartDate);
    final end = _dateOnly(weeklyEndDate);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class DaySales {
  const DaySales({required this.individual, required this.store});

  final double individual;
  final double store;

  DaySales add({required double individual, required double store}) {
    return DaySales(
      individual: this.individual + individual,
      store: this.store + store,
    );
  }
}

class HistoryPeriod {
  const HistoryPeriod({required this.month, required this.year});

  final int month;
  final int year;

  DateTime get start => DateTime(year, month);

  DateTime get endExclusive => DateTime(year, month + 1);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  String get label {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Marco',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[month - 1]} $year';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HistoryPeriod && other.month == month && other.year == year;
  }

  @override
  int get hashCode => Object.hash(month, year);
}
