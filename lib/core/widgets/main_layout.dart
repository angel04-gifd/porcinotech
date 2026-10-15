import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child});
  final Widget child;
  static const _items = [
    ('Inicio', Icons.home_outlined, '/dashboard'),
    ('Cerdos', Icons.pets_outlined, '/cerdos'),
    ('Corrales', Icons.grid_view_outlined, '/corrales'),
    ('Partos', Icons.favorite_outline, '/partos'),
    ('Alimento', Icons.grass_outlined, '/alimentos'),
  ];
  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((item) => item.$3 == path);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PorcinoTech'),
        actions: [
          IconButton(
            onPressed: () => context.go('/perfil'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (value) => context.go(_items[value].$3),
        destinations: _items
            .map(
              (item) =>
                  NavigationDestination(icon: Icon(item.$2), label: item.$1),
            )
            .toList(),
      ),
    );
  }
}
