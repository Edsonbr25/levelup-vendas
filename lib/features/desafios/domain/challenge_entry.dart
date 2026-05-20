class ChallengeEntry {
  const ChallengeEntry({
    required this.date,
    required this.type,
    required this.amount,
    this.notes,
  });

  final DateTime date;
  final ChallengeType type;
  final double amount;
  final String? notes;

  String get typeLabel => type.label;

  Map<String, dynamic> toSupabase() {
    return {
      'challenge_date': _dateOnly(date),
      'challenge_type': type.value,
      'challenge_amount': amount,
      'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory ChallengeEntry.fromSupabase(Map<String, dynamic> row) {
    return ChallengeEntry(
      date:
          DateTime.tryParse(row['challenge_date']?.toString() ?? '') ??
          DateTime.now(),
      type: ChallengeType.fromValue(row['challenge_type']?.toString()),
      amount: _toDouble(row['challenge_amount']),
      notes: row['notes']?.toString(),
    );
  }

  static List<ChallengeEntry> legacyFromSupabase(Map<String, dynamic> row) {
    final date =
        DateTime.tryParse(row['challenge_date']?.toString() ?? '') ??
        DateTime.tryParse(row['created_at']?.toString() ?? '') ??
        DateTime.now();

    return [
      ..._legacyEntries(
        date: date,
        type: ChallengeType.storeGoal,
        count: _toInt(row['store_goal_challenge']),
      ),
      ..._legacyEntries(
        date: date,
        type: ChallengeType.pa,
        count: _toInt(row['pa_challenge']),
      ),
      ..._legacyEntries(
        date: date,
        type: ChallengeType.biggestTicket,
        count: _toInt(row['biggest_ticket_challenge']),
      ),
    ];
  }

  static List<ChallengeEntry> _legacyEntries({
    required DateTime date,
    required ChallengeType type,
    required int count,
  }) {
    return [
      for (var index = 0; index < count; index++)
        ChallengeEntry(
          date: date,
          type: type,
          amount: 0,
          notes: 'Migrado do formato antigo',
        ),
    ];
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }
}

enum ChallengeType {
  storeGoal('store_goal', 'Meta loja'),
  pa('pa', 'P.A'),
  biggestTicket('biggest_ticket', 'Maior boleta');

  const ChallengeType(this.value, this.label);

  final String value;
  final String label;

  static ChallengeType fromValue(String? value) {
    return ChallengeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChallengeType.storeGoal,
    );
  }
}
