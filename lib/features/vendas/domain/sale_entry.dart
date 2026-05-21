class SaleEntry {
  const SaleEntry({
    this.id,
    required this.date,
    required this.individualSale,
    required this.storeSale,
  });

  final String? id;
  final DateTime date;
  final double individualSale;
  final double storeSale;

  factory SaleEntry.fromSupabase(Map<String, dynamic> row) {
    return SaleEntry(
      id: row['id']?.toString(),
      date:
          DateTime.tryParse(row['sale_date']?.toString() ?? '') ??
          DateTime(1900),
      individualSale: _toDouble(row['daily_individual_sale']),
      storeSale: _toDouble(row['daily_store_sale']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'sale_date': _dateOnly(date),
      'daily_individual_sale': individualSale,
      'daily_store_sale': storeSale,
    };
  }

  SaleEntry copyWith({
    String? id,
    DateTime? date,
    double? individualSale,
    double? storeSale,
  }) {
    return SaleEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      individualSale: individualSale ?? this.individualSale,
      storeSale: storeSale ?? this.storeSale,
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
