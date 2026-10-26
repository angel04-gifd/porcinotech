import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../main.dart' show RestartWidget;
import '../../auth/data/auth_repository.dart';

/// Elegir granja: el administrador autorizado crea una nueva; todas las demás
/// cuentas se unen con el código que les dio un administrador (y quedan como
/// operadores).
class FarmSetupScreen extends ConsumerStatefulWidget {
  const FarmSetupScreen({super.key});
  @override
  ConsumerState<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends ConsumerState<FarmSetupScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      // Reinicia el estado para que se carguen los datos de la granja elegida.
      RestartWidget.restart(context);
    } catch (e) {
      final text = e.toString();
      setState(() {
        _busy = false;
        _error = text.contains('message:')
            ? text.split('message:').last.split(',').first.trim()
            : 'No se pudo completar. Revisa tu conexión e inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFarm = ref.watch(currentFarmProvider) != null;
    // Solo el administrador autorizado puede crear granjas; los demás se unen
    // con un código y entran como operadores.
    final checking = ref.watch(adminAutorizadoProvider).isLoading;
    final canCreate = !checking && ref.watch(puedeCrearGranjaProvider);
    final canJoin = !checking && ref.watch(puedeUnirseGranjaProvider);
    final repo = ref.read(authRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu granja'),
        leading: hasFarm
            ? BackButton(onPressed: () => context.go('/perfil'))
            : null,
        automaticallyImplyLeading: false,
        actions: [
          if (!hasFarm)
            TextButton(
              onPressed: _busy ? null : () => repo.signOut(),
              child: const Text('Cerrar sesión'),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', height: 110),
                const SizedBox(height: 12),
                Text(
                  hasFarm
                      ? (canCreate ? 'Agrega otra granja' : 'Únete a otra granja')
                      : (canCreate
                            ? '¡Bienvenido! ¿Cómo vas a usar PorcinoTech?'
                            : '¡Bienvenido! Únete a tu granja con el código que te dio tu administrador.'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (canCreate) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soy administrador: crear una granja',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tendrás control total de esa granja y podrás crear todas las que necesites. Cada una tiene sus propios datos.',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la granja',
                            hintText: 'Ej. Granja El Mezquital',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(() => repo.crearGranja(_name.text)),
                          icon: const Icon(Icons.add_home_work_outlined),
                          label: const Text('Crear granja'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ],
                if (canJoin)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soy operador: unirme con un código',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pídele el código al administrador de la granja (lo ve en su perfil).',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _code,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Código de la granja',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => repo.unirseAGranja(_code.text),
                                ),
                          icon: const Icon(Icons.login),
                          label: const Text('Unirme'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_busy || checking)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
