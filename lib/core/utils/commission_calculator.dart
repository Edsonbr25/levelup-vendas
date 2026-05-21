enum GoalKind { individual, store }

class CommissionBand {
  const CommissionBand({required this.percent, required this.commissionRate});

  final double percent;
  final double commissionRate;
}

class CommissionResult {
  const CommissionResult({
    required this.sales,
    required this.goal,
    required this.percentReached,
    required this.appliedRate,
    required this.commission,
    required this.currentBandPercent,
    required this.nextBandPercent,
    required this.amountToNextBand,
    required this.amountToFirstBand,
  });

  final double sales;
  final double goal;
  final double percentReached;
  final double appliedRate;
  final double commission;
  final double currentBandPercent;
  final double? nextBandPercent;
  final double amountToNextBand;
  final double amountToFirstBand;

  bool get isCommissioning => appliedRate > 0;
  bool get hasNextBand => nextBandPercent != null && amountToNextBand > 0;
}

class GoalRangeTarget {
  const GoalRangeTarget({
    required this.percent,
    required this.total,
    required this.daily,
    required this.commissionRate,
  });

  final double percent;
  final double total;
  final double daily;
  final double commissionRate;
}

class CommissionCalculator {
  const CommissionCalculator._();

  static const individualBands = [
    CommissionBand(percent: 90, commissionRate: 3),
    CommissionBand(percent: 100, commissionRate: 5),
    CommissionBand(percent: 120, commissionRate: 6),
  ];

  static const storeBands = [
    CommissionBand(percent: 95, commissionRate: 0.5),
    CommissionBand(percent: 100, commissionRate: 2),
    CommissionBand(percent: 120, commissionRate: 3),
  ];

  static CommissionResult individual({
    required double sales,
    required double goal,
  }) {
    return calculate(sales: sales, goal: goal, bands: individualBands);
  }

  static CommissionResult store({required double sales, required double goal}) {
    return calculate(sales: sales, goal: goal, bands: storeBands);
  }

  static CommissionResult calculate({
    required double sales,
    required double goal,
    required List<CommissionBand> bands,
  }) {
    final percentReached = goal <= 0 ? 0.0 : (sales / goal) * 100;
    var appliedRate = 0.0;
    var currentBandPercent = 0.0;

    for (final band in bands) {
      if (percentReached >= band.percent) {
        appliedRate = band.commissionRate;
        currentBandPercent = band.percent;
      }
    }

    CommissionBand? nextBand;
    for (final band in bands) {
      if (percentReached < band.percent) {
        nextBand = band;
        break;
      }
    }

    final firstTarget = goal * (bands.first.percent / 100);
    final nextTarget = nextBand == null
        ? sales
        : goal * (nextBand.percent / 100);

    return CommissionResult(
      sales: sales,
      goal: goal,
      percentReached: percentReached,
      appliedRate: appliedRate,
      commission: sales * (appliedRate / 100),
      currentBandPercent: currentBandPercent,
      nextBandPercent: nextBand?.percent,
      amountToNextBand: (nextTarget - sales).clamp(0, double.infinity),
      amountToFirstBand: (firstTarget - sales).clamp(0, double.infinity),
    );
  }

  static List<GoalRangeTarget> monthlyTargets({
    required double goal,
    required int days,
    required List<CommissionBand> bands,
  }) {
    final safeDays = days <= 0 ? 1 : days;
    return [
      for (final band in bands)
        GoalRangeTarget(
          percent: band.percent,
          total: goal * (band.percent / 100),
          daily: (goal * (band.percent / 100)) / safeDays,
          commissionRate: band.commissionRate,
        ),
    ];
  }

  static int daysInMonth([DateTime? date]) {
    final base = date ?? DateTime.now();
    return DateTime(base.year, base.month + 1, 0).day;
  }
}
