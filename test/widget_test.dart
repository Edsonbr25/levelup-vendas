import 'package:flutter/material.dart';
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

  for (final size in const [Size(375, 667), Size(390, 844), Size(412, 915)]) {
    testWidgets('Dashboard is responsive at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: LevelUpApp()));
      await tester.pumpAndSettle();

      expect(find.text('LevelUp Vendas'), findsWidgets);
      expect(find.text('Proximo nivel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Historico page is responsive at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const ProviderScope(child: LevelUpApp()));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.history_rounded).last);
        await tester.pumpAndSettle();

        expect(find.text('Historico'), findsOneWidget);
        expect(find.text('Exportar PDF'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
