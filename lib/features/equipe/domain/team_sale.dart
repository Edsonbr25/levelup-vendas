enum SaleType {
  store('store', 'Loja'),
  seller('seller', 'Vendedor');

  const SaleType(this.value, this.label);

  final String value;
  final String label;

  static SaleType fromValue(Object? value) {
    return SaleType.values.firstWhere(
      (type) => type.value == value?.toString(),
      orElse: () => SaleType.seller,
    );
  }
}

class TeamSale {
  const TeamSale({
    this.id,
    required this.date,
    this.sellerId,
    this.sellerName,
    required this.amount,
    required this.type,
  });

  final String? id;
  final DateTime date;
  final String? sellerId;
  final String? sellerName;
  final double amount;
  final SaleType type;

  factory TeamSale.fromSupabase(Map<String, dynamic> row) {
    return TeamSale(
      id: row['id']?.toString(),
      date:
          DateTime.tryParse(row['sale_date']?.toString() ?? '') ??
          DateTime(1900),
      sellerId: row['seller_id']?.toString(),
      sellerName: row['seller_name']?.toString(),
      amount: _toDouble(row['sale_amount']),
      type: SaleType.fromValue(row['sale_type']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'sale_date': _dateOnly(date),
      'seller_id': sellerId,
      'seller_name': sellerName,
      'sale_amount': amount,
      'sale_type': type.value,
    };
  }

  TeamSale copyWith({
    String? id,
    DateTime? date,
    String? sellerId,
    String? sellerName,
    double? amount,
    SaleType? type,
  }) {
    return TeamSale(
      id: id ?? this.id,
      date: date ?? this.date,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
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
