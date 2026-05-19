import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:levelup_vendas/main.dart';

void main() {
  testWidgets('LevelUp app renders dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LevelUpApp()));
    await tester.pumpAndSettle();

    expect(find.text('LevelUp Vendas'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Venda individual hoje'), findsOneWidget);
  });
}
