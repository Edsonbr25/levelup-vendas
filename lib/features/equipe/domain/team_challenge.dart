enum TeamChallengeType {
  storeGoal('store_goal', 'Meta loja'),
  biggestTicket('biggest_ticket', 'Maior boleta'),
  pa('pa', 'P.A');

  const TeamChallengeType(this.value, this.label);

  final String value;
  final String label;

  static TeamChallengeType fromValue(Object? value) {
    return TeamChallengeType.values.firstWhere(
      (type) => type.value == value?.toString(),
      orElse: () => TeamChallengeType.storeGoal,
    );
  }
}

class TeamChallenge {
  const TeamChallenge({
    this.id,
    required this.date,
    this.sellerId,
    this.sellerName,
    required this.type,
    required this.amount,
    this.notes,
  });

  final String? id;
  final DateTime date;
  final String? sellerId;
  final String? sellerName;
  final TeamChallengeType type;
  final double amount;
  final String? notes;

  factory TeamChallenge.fromSupabase(Map<String, dynamic> row) {
    return TeamChallenge(
      id: row['id']?.toString(),
      date:
          DateTime.tryParse(row['challenge_date']?.toString() ?? '') ??
          DateTime(1900),
      sellerId: row['seller_id']?.toString(),
      sellerName: row['seller_name']?.toString(),
      type: TeamChallengeType.fromValue(row['challenge_type']),
      amount: _toDouble(row['challenge_amount']),
      notes: row['notes']?.toString(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'challenge_date': _dateOnly(date),
      'seller_id': sellerId,
      'seller_name': sellerName,
      'challenge_type': type.value,
      'challenge_amount': amount,
      'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    };
  }

  TeamChallenge copyWith({
    String? id,
    DateTime? date,
    String? sellerId,
    String? sellerName,
    TeamChallengeType? type,
    double? amount,
    String? notes,
  }) {
    return TeamChallenge(
      id: id ?? this.id,
      date: date ?? this.date,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
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
