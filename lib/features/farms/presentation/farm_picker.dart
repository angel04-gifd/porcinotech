import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../main.dart' show RestartWidget;
import '../../auth/data/auth_repository.dart';

/// Hoja inferior para cambiar de granja o agregar otra.
Future<void> showFarmPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (_, ref, _) {
        final farms = ref.watch(misGranjasProvider).valueOrNull ?? const [];
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Mis granjas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Cada granja tiene sus propios datos.'),
              ),
              for (final farm in farms)
                ListTile(
                  leading: Icon(
                    farm['activa'] == true
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                  ),
                  title: Text('${farm['nombre']}'),
                  subtitle: Text(
                    farm['rol'] == 'admin' ? 'Administrador' : 'Operador',
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (farm['activa'] == true) return;
                    await ref
                        .read(authRepositoryProvider)
                        .cambiarGranja('${farm['id']}');
                    if (context.mounted) RestartWidget.restart(context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(
                  textoAgregarGranja(
                    ref.watch(puedeCrearGranjaProvider),
                    ref.watch(puedeUnirseGranjaProvider),
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/granja');
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
