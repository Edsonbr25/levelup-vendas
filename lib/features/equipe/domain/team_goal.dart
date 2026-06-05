enum GoalOwnerType {
  store('store', 'Loja'),
  seller('seller', 'Vendedor');

  const GoalOwnerType(this.value, this.label);

  final String value;
  final String label;

  static GoalOwnerType fromValue(Object? value) {
    return GoalOwnerType.values.firstWhere(
      (type) => type.value == value?.toString(),
      orElse: () => GoalOwnerType.seller,
    );
  }
}

enum GoalPeriodType {
  weekly('weekly', 'Semanal'),
  monthly('monthly', 'Mensal');

  const GoalPeriodType(this.value, this.label);

  final String value;
  final String label;

  static GoalPeriodType fromValue(Object? value) {
    return GoalPeriodType.values.firstWhere(
      (type) => type.value == value?.toString(),
      orElse: () => GoalPeriodType.monthly,
    );
  }
}

class TeamGoal {
  const TeamGoal({
    this.id,
    required this.ownerType,
    this.sellerId,
    this.sellerName,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.amount,
  });

  final String? id;
  final GoalOwnerType ownerType;
  final String? sellerId;
  final String? sellerName;
  final GoalPeriodType periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double amount;

  factory TeamGoal.fromSupabase(Map<String, dynamic> row) {
    return TeamGoal(
      id: row['id']?.toString(),
      ownerType: GoalOwnerType.fromValue(row['goal_type']),
      sellerId: row['seller_id']?.toString(),
      sellerName: row['seller_name']?.toString(),
      periodType: GoalPeriodType.fromValue(row['period_type']),
      periodStart:
          DateTime.tryParse(row['period_start']?.toString() ?? '') ??
          DateTime(1900),
      periodEnd:
          DateTime.tryParse(row['period_end']?.toString() ?? '') ??
          DateTime(1900),
      amount: _toDouble(row['goal_amount']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'goal_type': ownerType.value,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'period_type': periodType.value,
      'period_start': _dateOnly(periodStart),
      'period_end': _dateOnly(periodEnd),
      'goal_amount': amount,
    };
  }

  bool matches({
    required GoalOwnerType owner,
    String? seller,
    required GoalPeriodType period,
  }) {
    return ownerType == owner && sellerId == seller && periodType == period;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }
}
