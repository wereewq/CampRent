import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AdaptiveScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final size = screenSizeOf(context);

    final destinations = [
      const NavigationDestination(icon: Icon(Icons.kayaking), label: 'Каталог'),
      if (auth.role == Role.reader)
        const NavigationDestination(
          icon: Icon(Icons.bookmark),
          label: 'Мои аренды',
        ),
      if (auth.has(Role.librarian))
        const NavigationDestination(
          icon: Icon(Icons.assignment_turned_in),
          label: 'Приёмка',
        ),
      if (auth.has(Role.admin))
        const NavigationDestination(
          icon: Icon(Icons.analytics),
          label: 'Аналитика',
        ),
    ];

    final railDestinations = destinations
        .map(
          (d) => NavigationRailDestination(icon: d.icon, label: Text(d.label)),
        )
        .toList();

    void onNavigate(int idx) {
      final routes = [
        '/catalog',
        if (auth.role == Role.reader) '/my-rentals',
        if (auth.has(Role.librarian)) '/instructor',
        if (auth.has(Role.admin)) '/admin-panel',
      ];
      if (idx < routes.length) context.go(routes[idx]);
    }

    final appBar = AppBar(
      title: const Text('CampRent — Сервис проката'),
      actions: [
        if (auth.isAuthenticated) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${auth.user?.fullName} (${auth.role.title})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ],
    );

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: child,
      ),
    );

    if (size == ScreenSize.compact) {
      return Scaffold(
        appBar: appBar,
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex.clamp(0, destinations.length - 1),
          destinations: destinations,
          onDestinationSelected: onNavigate,
        ),
      );
    }

    final isExpanded = size == ScreenSize.expanded || size == ScreenSize.ultra;
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex.clamp(0, railDestinations.length - 1),
            extended: isExpanded,
            labelType: isExpanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: railDestinations,
            onDestinationSelected: onNavigate,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}
