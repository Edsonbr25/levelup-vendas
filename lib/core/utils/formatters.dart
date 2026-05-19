import 'package:intl/intl.dart';

final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
final _percent = NumberFormat.decimalPercentPattern(
  locale: 'pt_BR',
  decimalDigits: 1,
);

String money(num value) => _currency.format(value);

String percent(num value) => _percent.format(value / 100);

double parseMoney(String value) {
  final normalized = value
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();
  return double.tryParse(normalized) ?? 0;
}
