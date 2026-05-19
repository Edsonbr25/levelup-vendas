import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _Destination('Dashboard', Icons.dashboard_rounded, '/'),
    _Destination('Metas', Icons.flag_rounded, '/metas'),
    _Destination('Vendas', Icons.point_of_sale_rounded, '/vendas'),
    _Destination('Desafios', Icons.emoji_events_rounded, '/desafios'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;
    final currentIndex = _currentIndex(context);

    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: child,
          ),
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              extended: width >= 1080,
              labelType: width >= 1080
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: _BrandMark(),
              ),
              destinations: [
                for (final item in _destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
              onDestinationSelected: (index) =>
                  context.go(_destinations[index].path),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        items: [
          for (final item in _destinations)
            BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
        ],
        onTap: (index) => context.go(_destinations[index].path),
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _destinations.indexWhere((item) => item.path == path);
    return index < 0 ? 0 : index;
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.trending_up_rounded, color: Colors.black),
        ),
        if (MediaQuery.sizeOf(context).width >= 1080) ...[
          const SizedBox(width: 12),
          const Text(
            AppConstants.appName,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ],
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
