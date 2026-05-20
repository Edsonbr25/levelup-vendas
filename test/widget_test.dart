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

  testWidgets('Historico page is responsive at 375px', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: LevelUpApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Historico'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
