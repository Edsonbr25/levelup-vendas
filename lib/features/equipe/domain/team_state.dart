import '../../../core/utils/commission_calculator.dart';
import 'seller.dart';
import 'team_challenge.dart';
import 'team_goal.dart';
import 'team_sale.dart';

class TeamState {
  const TeamState({
    required this.sellers,
    required this.sales,
    required this.goals,
    required this.challenges,
    required this.periodStart,
    required this.periodEnd,
    this.isFallback = false,
    this.errorMessage,
  });

  factory TeamState.empty() {
    final now = DateTime.now();
    return TeamState(
      sellers: const [],
      sales: const [],
      goals: const [],
      challenges: const [],
      periodStart: DateTime(now.year, now.month),
      periodEnd: DateTime(
        now.year,
        now.month + 1,
      ).subtract(const Duration(days: 1)),
    );
  }

  factory TeamState.mock() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(
      now.year,
      now.month + 1,
    ).subtract(const Duration(days: 1));
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sellers = const [
      Seller(id: 'seller-1', name: 'Edson Pires', role: 'Coordenador'),
      Seller(id: 'seller-2', name: 'Ana Paula', role: 'Vendedora'),
      Seller(id: 'seller-3', name: 'Carlos Lima', role: 'Vendedor'),
    ];

    return TeamState(
      sellers: sellers,
      periodStart: monthStart,
      periodEnd: monthEnd,
      goals: [
        TeamGoal(
          ownerType: GoalOwnerType.store,
          periodType: GoalPeriodType.monthly,
          periodStart: monthStart,
          periodEnd: monthEnd,
          amount: 420000,
        ),
        TeamGoal(
          ownerType: GoalOwnerType.store,
          periodType: GoalPeriodType.weekly,
          periodStart: weekStart,
          periodEnd: weekStart.add(const Duration(days: 6)),
          amount: 105000,
        ),
        for (final seller in sellers) ...[
          TeamGoal(
            ownerType: GoalOwnerType.seller,
            sellerId: seller.id,
            sellerName: seller.name,
            periodType: GoalPeriodType.monthly,
            periodStart: monthStart,
            periodEnd: monthEnd,
            amount: 85000,
          ),
          TeamGoal(
            ownerType: GoalOwnerType.seller,
            sellerId: seller.id,
            sellerName: seller.name,
            periodType: GoalPeriodType.weekly,
            periodStart: weekStart,
            periodEnd: weekStart.add(const Duration(days: 6)),
            amount: 21250,
          ),
        ],
      ],
      sales: [
        TeamSale(
          date: now,
          amount: 189000,
          type: SaleType.store,
          sellerName: 'Loja',
        ),
        TeamSale(
          date: now,
          sellerId: 'seller-1',
          sellerName: 'Edson Pires',
          amount: 64000,
          type: SaleType.seller,
        ),
        TeamSale(
          date: now,
          sellerId: 'seller-2',
          sellerName: 'Ana Paula',
          amount: 58000,
          type: SaleType.seller,
        ),
        TeamSale(
          date: now,
          sellerId: 'seller-3',
          sellerName: 'Carlos Lima',
          amount: 42000,
          type: SaleType.seller,
        ),
      ],
      challenges: [
        TeamChallenge(
          date: now,
          sellerId: 'seller-1',
          sellerName: 'Edson Pires',
          type: TeamChallengeType.storeGoal,
          amount: 50,
        ),
        TeamChallenge(
          date: now,
          sellerId: 'seller-2',
          sellerName: 'Ana Paula',
          type: TeamChallengeType.biggestTicket,
          amount: 70,
        ),
        TeamChallenge(
          date: now,
          sellerId: 'seller-2',
          sellerName: 'Ana Paula',
          type: TeamChallengeType.pa,
          amount: 30,
        ),
      ],
      isFallback: true,
      errorMessage: 'Usando dados locais temporarios.',
    );
  }

  final List<Seller> sellers;
  final List<TeamSale> sales;
  final List<TeamGoal> goals;
  final List<TeamChallenge> challenges;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool isFallback;
  final String? errorMessage;

  List<TeamSale> get monthSales => sales.where(_inPeriod).toList();

  List<TeamChallenge> get monthChallenges =>
      challenges.where((entry) => _dateInPeriod(entry.date)).toList();

  double get monthlyStoreSales => monthSales
      .where((sale) => sale.type == SaleType.store)
      .fold(0, (total, sale) => total + sale.amount);

  double get monthlyTeamSales => monthSales
      .where((sale) => sale.type == SaleType.seller)
      .fold(0, (total, sale) => total + sale.amount);

  double get monthlyChallengeTotal =>
      monthChallenges.fold(0, (total, entry) => total + entry.amount);

  double get monthlyStoreGoal =>
      _goalAmount(GoalOwnerType.store, null, GoalPeriodType.monthly);

  double get weeklyStoreGoal =>
      _goalAmount(GoalOwnerType.store, null, GoalPeriodType.weekly);

  List<SellerSalesRanking> get salesRanking {
    final ranking = [
      for (final seller in sellers.where((seller) => seller.isActive))
        SellerSalesRanking(
          seller: seller,
          monthlySales: _sellerSales(seller.id, periodStart, periodEnd),
          weeklySales: _sellerSales(
            seller.id,
            weeklyStartFor(seller.id),
            weeklyEndFor(seller.id),
          ),
          monthlyGoal: _goalAmount(
            GoalOwnerType.seller,
            seller.id,
            GoalPeriodType.monthly,
          ),
          weeklyGoal: _goalAmount(
            GoalOwnerType.seller,
            seller.id,
            GoalPeriodType.weekly,
          ),
        ),
    ];
    ranking.sort((a, b) => b.monthlySales.compareTo(a.monthlySales));
    return ranking;
  }

  List<ChallengeRanking> challengeRanking({TeamChallengeType? type}) {
    final map = <String, ChallengeRanking>{};
    for (final entry in monthChallenges.where(
      (entry) => type == null || entry.type == type,
    )) {
      final key = entry.sellerId ?? entry.sellerName ?? 'sem-vendedor';
      final current =
          map[key] ??
          ChallengeRanking(
            sellerId: entry.sellerId,
            sellerName: entry.sellerName ?? 'Sem vendedor',
            count: 0,
            amount: 0,
          );
      map[key] = current.copyWith(
        count: current.count + 1,
        amount: current.amount + entry.amount,
      );
    }
    final ranking = map.values.toList()
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        return byCount == 0 ? b.amount.compareTo(a.amount) : byCount;
      });
    return ranking;
  }

  SellerSalesRanking? get bestSeller =>
      salesRanking.isEmpty ? null : salesRanking.first;

  ChallengeRanking? get bestChallengeSeller {
    final ranking = challengeRanking();
    return ranking.isEmpty ? null : ranking.first;
  }

  double sellerMonthlyCommission(Seller seller) {
    final sales = _sellerSales(seller.id, periodStart, periodEnd);
    final goal = _goalAmount(
      GoalOwnerType.seller,
      seller.id,
      GoalPeriodType.monthly,
    );
    return CommissionCalculator.individual(sales: sales, goal: goal).commission;
  }

  double get storeCommission => CommissionCalculator.store(
    sales: monthlyStoreSales,
    goal: monthlyStoreGoal,
  ).commission;

  double get estimatedCommissionTotal {
    final sellerTotal = sellers.fold(
      0.0,
      (total, seller) => total + sellerMonthlyCommission(seller),
    );
    return sellerTotal + storeCommission;
  }

  DateTime weeklyStartFor(String? sellerId) {
    final goal = _latestGoal(
      GoalOwnerType.seller,
      sellerId,
      GoalPeriodType.weekly,
    );
    return goal?.periodStart ?? _defaultWeekStart();
  }

  DateTime weeklyEndFor(String? sellerId) {
    final goal = _latestGoal(
      GoalOwnerType.seller,
      sellerId,
      GoalPeriodType.weekly,
    );
    return goal?.periodEnd ?? _defaultWeekStart().add(const Duration(days: 6));
  }

  DateTime get storeWeeklyStart =>
      _latestGoal(
        GoalOwnerType.store,
        null,
        GoalPeriodType.weekly,
      )?.periodStart ??
      _defaultWeekStart();

  DateTime get storeWeeklyEnd =>
      _latestGoal(
        GoalOwnerType.store,
        null,
        GoalPeriodType.weekly,
      )?.periodEnd ??
      _defaultWeekStart().add(const Duration(days: 6));

  double get weeklyStoreSales => sales
      .where((sale) => sale.type == SaleType.store)
      .where(
        (sale) => _dateBetween(sale.date, storeWeeklyStart, storeWeeklyEnd),
      )
      .fold(0, (total, sale) => total + sale.amount);

  double get weeklyStorePercent => _ratio(weeklyStoreSales, weeklyStoreGoal);

  double _sellerSales(String? sellerId, DateTime start, DateTime end) {
    return sales
        .where((sale) => sale.type == SaleType.seller)
        .where((sale) => sale.sellerId == sellerId)
        .where((sale) => _dateBetween(sale.date, start, end))
        .fold(0, (total, sale) => total + sale.amount);
  }

  double _goalAmount(
    GoalOwnerType ownerType,
    String? sellerId,
    GoalPeriodType periodType,
  ) {
    return _latestGoal(ownerType, sellerId, periodType)?.amount ?? 0;
  }

  TeamGoal? _latestGoal(
    GoalOwnerType ownerType,
    String? sellerId,
    GoalPeriodType periodType,
  ) {
    final matches =
        goals
            .where(
              (goal) =>
                  goal.ownerType == ownerType &&
                  goal.periodType == periodType &&
                  goal.sellerId == sellerId,
            )
            .toList()
          ..sort((a, b) => b.periodStart.compareTo(a.periodStart));
    return matches.isEmpty ? null : matches.first;
  }

  bool _inPeriod(TeamSale sale) => _dateInPeriod(sale.date);

  bool _dateInPeriod(DateTime date) =>
      _dateBetween(date, periodStart, periodEnd);

  static bool _dateBetween(DateTime date, DateTime start, DateTime end) {
    final normalized = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return !normalized.isBefore(normalizedStart) &&
        !normalized.isAfter(normalizedEnd);
  }

  static double _ratio(double value, double target) {
    if (target <= 0) return 0;
    return (value / target) * 100;
  }

  DateTime _defaultWeekStart() {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }
}

class SellerSalesRanking {
  const SellerSalesRanking({
    required this.seller,
    required this.monthlySales,
    required this.weeklySales,
    required this.monthlyGoal,
    required this.weeklyGoal,
  });

  final Seller seller;
  final double monthlySales;
  final double weeklySales;
  final double monthlyGoal;
  final double weeklyGoal;

  double get monthlyPercent =>
      monthlyGoal <= 0 ? 0 : (monthlySales / monthlyGoal) * 100;
  double get weeklyPercent =>
      weeklyGoal <= 0 ? 0 : (weeklySales / weeklyGoal) * 100;
}

class ChallengeRanking {
  const ChallengeRanking({
    required this.sellerId,
    required this.sellerName,
    required this.count,
    required this.amount,
  });

  final String? sellerId;
  final String sellerName;
  final int count;
  final double amount;

  ChallengeRanking copyWith({int? count, double? amount}) {
    return ChallengeRanking(
      sellerId: sellerId,
      sellerName: sellerName,
      count: count ?? this.count,
      amount: amount ?? this.amount,
    );
  }
}
