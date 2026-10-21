import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../farms/presentation/farm_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editData(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> profile,
  ) async {
    final name = TextEditingController(text: '${profile['nombre'] ?? ''}');
    final phone = TextEditingController(text: '${profile['telefono'] ?? ''}');
    final job = TextEditingController(text: '${profile['puesto'] ?? ''}');
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mis datos personales'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                maxLength: 20,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: job,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Puesto o área',
                  hintText: 'Ej. Encargado de maternidad',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (save != true) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .guardarDatosPersonales(
            nombre: name.text,
            telefono: phone.text,
            puesto: job.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Datos guardados.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron guardar los datos.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserEmailProvider);
    final role = ref.watch(currentUserRoleProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final farm = ref.watch(currentFarmProvider);
    final farms = ref.watch(misGranjasProvider).valueOrNull ?? const [];
    final team = ref.watch(equipoGranjaProvider).valueOrNull ?? const [];
    final isAdmin = role.valueOrNull == 'admin';
    final texts = Theme.of(context).textTheme;

    String show(Object? v) =>
        (v == null || '$v'.trim().isEmpty) ? 'Sin capturar' : '$v';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 38)),
        const SizedBox(height: 12),
        Center(child: Text(email ?? '', style: texts.titleMedium)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  title: Text('Datos personales', style: texts.titleSmall),
                  trailing: profile == null
                      ? null
                      : TextButton.icon(
                          onPressed: () => _editData(context, ref, profile),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Nombre'),
                  subtitle: Text(show(profile?['nombre'])),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Teléfono'),
                  subtitle: Text(show(profile?['telefono'])),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Puesto'),
                  subtitle: Text(show(profile?['puesto'])),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Rol en esta granja'),
                  subtitle: role.when(
                    loading: () => const Text('Cargando rol...'),
                    error: (error, _) => Text('No se pudo validar el rol: $error'),
                    data: (value) => Text(
                      value == 'admin'
                          ? 'Administrador'
                          : value == 'operador'
                          ? 'Operador'
                          : 'Sin perfil',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  title: Text('Mi granja', style: texts.titleSmall),
                  trailing: TextButton.icon(
                    onPressed: () => showFarmPicker(context, ref),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: Text(farms.length > 1 ? 'Cambiar' : 'Agregar'),
                  ),
                ),
                if (farm == null)
                  const ListTile(
                    leading: Icon(Icons.home_work_outlined),
                    title: Text('Sin granja activa'),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.home_work_outlined),
                    title: Text('${farm['nombre']}'),
                    subtitle: Text(
                      isAdmin
                          ? 'Código para invitar operadores: ${farm['codigo_invitacion']}'
                          : 'Perteneces como operador',
                    ),
                    trailing: isAdmin
                        ? IconButton(
                            tooltip: 'Copiar código',
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: '${farm['codigo_invitacion']}',
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Código copiado.')),
                              );
                            },
                          )
                        : null,
                  ),
                if (farms.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Tienes ${farms.length} granjas. Cada una guarda sus propios datos.',
                      style: texts.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Equipo de la granja', style: texts.titleSmall),
                    subtitle: const Text(
                      'Quién es cada operador y cómo contactarlo.',
                    ),
                  ),
                  if (team.isEmpty)
                    const ListTile(
                      dense: true,
                      title: Text('Aún no hay integrantes.'),
                    ),
                  for (final member in team)
                    ListTile(
                      leading: Icon(
                        member['rol'] == 'admin'
                            ? Icons.verified_user_outlined
                            : Icons.person_outline,
                      ),
                      title: Text(show(member['nombre'])),
                      subtitle: Text(
                        [
                          member['rol'] == 'admin' ? 'Administrador' : 'Operador',
                          if ('${member['puesto'] ?? ''}'.isNotEmpty)
                            '${member['puesto']}',
                          if ('${member['telefono'] ?? ''}'.isNotEmpty)
                            '${member['telefono']}',
                          if ('${member['correo'] ?? ''}'.isNotEmpty)
                            '${member['correo']}',
                        ].join(' · '),
                      ),
                      trailing: member['rol'] == 'admin'
                          ? null
                          : IconButton(
                              tooltip: 'Quitar de la granja',
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (d) => AlertDialog(
                                    title: const Text('Quitar operador'),
                                    content: Text(
                                      '¿Quitar a ${show(member['nombre'])} de esta granja? Sus registros se conservan.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(d, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(d, true),
                                        child: const Text('Quitar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true) return;
                                await ref
                                    .read(authRepositoryProvider)
                                    .quitarOperador('${member['user_id']}');
                                ref.invalidate(equipoGranjaProvider);
                              },
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.rule_outlined),
            title: const Text('Permisos'),
            subtitle: Text(
              isAdmin
                  ? 'Administrador: control total de esta granja. Crea, edita y elimina cerdos, corrales, alimentos, stock y partos, y administra el equipo.'
                  : 'Operador: registra y edita cerdos, inseminaciones, partos y consumos; cambia el estado de los corrales. No crea ni elimina corrales ni alimentos, no elimina registros ni cambia roles.',
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.go('/granja'),
            child: Text(
              textoAgregarGranja(
                ref.watch(puedeCrearGranjaProvider),
                ref.watch(puedeUnirseGranjaProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
