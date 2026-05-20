import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/desafios/presentation/desafios_page.dart';
import '../features/historico/presentation/historico_page.dart';
import '../features/metas/presentation/metas_page.dart';
import '../features/vendas/presentation/vendas_page.dart';
import '../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/metas',
            name: 'metas',
            builder: (context, state) => const MetasPage(),
          ),
          GoRoute(
            path: '/vendas',
            name: 'vendas',
            builder: (context, state) => const VendasPage(),
          ),
          GoRoute(
            path: '/desafios',
            name: 'desafios',
            builder: (context, state) => const DesafiosPage(),
          ),
          GoRoute(
            path: '/historico',
            name: 'historico',
            builder: (context, state) => const HistoricoPage(),
          ),
        ],
      ),
    ],
  );
});
