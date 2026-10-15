import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserEmailProvider);
    final role = ref.watch(currentUserRoleProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 38)),
        const SizedBox(height: 18),
        Center(
          child: Text(
            email ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Rol'),
            subtitle: role.when(
              loading: () => const Text('Cargando rol...'),
              error: (error, _) => Text('No se pudo validar el rol: $error'),
              data: (value) => Text(value ?? 'Sin perfil'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Permisos'),
            subtitle: role.when(
              loading: () => const Text('Cargando permisos...'),
              error: (_, _) =>
                  const Text('No se pudieron validar los permisos.'),
              data: (value) => Text(
                value == 'admin'
                    ? 'Administrador: control total. Crea, edita y elimina cerdos, corrales, alimentos, stock y partos.'
                    : 'Operador: registra y edita cerdos, inseminaciones, partos y consumos; cambia el estado de los corrales. No crea ni elimina corrales ni alimentos, no elimina registros ni cambia roles.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
