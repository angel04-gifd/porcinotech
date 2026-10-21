import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/farms/presentation/farm_picker.dart';

class MainLayout extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = ref.watch(currentFarmProvider);
    final path = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((item) => item.$3 == path);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 34),
            const SizedBox(width: 10),
            const Text('PorcinoTech'),
          ],
        ),
        actions: [
          if (farm != null)
            TextButton.icon(
              onPressed: () => showFarmPicker(context, ref),
              icon: const Icon(Icons.home_work_outlined, size: 18),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text('${farm['nombre']}', overflow: TextOverflow.ellipsis),
              ),
            ),
          IconButton(
            onPressed: () => context.go('/perfil'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: child,
        ),
      ),
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
