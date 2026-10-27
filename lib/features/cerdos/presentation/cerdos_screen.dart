import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/error_view.dart';
import '../../auth/data/auth_repository.dart';
import '../../corrales/data/pen_repository.dart';
import '../../partos/data/farrowing_repository.dart';
import '../data/pig_repository.dart';
import '../data/pig_rules.dart';

const _pigStates = {
  'activo': 'Activo',
  'vendido': 'Vendido',
  'fallecido': 'Fallecido',
  'baja': 'Baja',
};

class CerdosScreen extends ConsumerWidget {
  const CerdosScreen({super.key});

  Future<void> _openPigForm(
    BuildContext context, {
    Map<String, dynamic>? pig,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PigForm(pig: pig),
  );

  Future<void> _showPigDetails(
    BuildContext context,
    Map<String, dynamic> pig,
    String penName,
    List<Map<String, dynamic>> farrowings,
  ) {
    final pending = pig['sexo'] == 'hembra'
        ? pendingFarrowingFor(pig['id'] as String, farrowings)
        : null;
    final birth = pig['fecha_nacimiento'] as String?;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Arete ${pig['arete']}'),
        content: SelectableText(
          'Nombre: ${pig['nombre'] ?? 'Sin nombre'}\n'
          'ID: ${pig['id']}\n'
          'Sexo: ${pig['sexo']}\n'
          'Raza: ${pig['raza'] ?? 'Sin raza'}\n'
          'Peso: ${pig['peso'] ?? 0} kg\n'
          'Nacimiento: ${birth == null ? 'Sin registrar' : DateFormat.yMMMd('es').format(DateTime.parse(birth))}\n'
          'Estado: ${_pigStates[pig['estado']] ?? pig['estado']}\n'
          'Corral: $penName'
          '${pending == null ? '' : '\nGestante · parto estimado ${DateFormat.yMMMd('es').format(DateTime.parse(pending['fecha_estimada_parto'] as String))}'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePig(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> pig,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cerdo'),
        content: Text(
          '¿Eliminar el cerdo ${pig['arete']}? Si tiene partos registrados se archivará como baja para conservar el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await ref
          .read(pigRepositoryProvider)
          .deleteOrArchivePig(pig['id'] as String);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'archivado'
                ? 'Cerdo archivado como baja porque tiene partos asociados.'
                : 'Cerdo eliminado.',
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar el cerdo: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentUserRoleProvider).valueOrNull == 'admin';
    final penNames = {
      for (final pen
          in ref.watch(pensProvider).valueOrNull ?? <Map<String, dynamic>>[])
        pen['id'] as String: pen['nombre'] as String,
    };
    final farrowings =
        ref.watch(farrowingsProvider).valueOrNull ?? <Map<String, dynamic>>[];
    return Scaffold(
      body: ref
          .watch(pigsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorView(
              title: 'No se pudieron cargar los cerdos',
              error: error,
              onRetry: () => ref.invalidate(pigsProvider),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay cerdos registrados. Usa "Agregar cerdo".',
                  ),
                );
              }
              // Activos primero; vendidos, fallecidos y bajas al final.
              final sorted = [
                ...rows.where((pig) => pig['estado'] == 'activo'),
                ...rows.where((pig) => pig['estado'] != 'activo'),
              ];
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                itemCount: sorted.length,
                itemBuilder: (context, i) {
                  final pig = sorted[i];
                  final active = pig['estado'] == 'activo';
                  final penName = penNames[pig['corral_id']] ?? 'Sin corral';
                  final pregnant =
                      pig['sexo'] == 'hembra' &&
                      pendingFarrowingFor(pig['id'] as String, farrowings) !=
                          null;
                  return Opacity(
                    opacity: active ? 1 : 0.55,
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            pig['sexo'] == 'hembra' ? Icons.female : Icons.male,
                          ),
                        ),
                        title: Text(
                          'Arete ${pig['arete']}'
                          '${pig['nombre'] == null ? '' : ' · ${pig['nombre']}'}',
                        ),
                        subtitle: Text(
                          '$penName · ${pig['peso'] ?? 0} kg'
                          '${pregnant ? ' · Gestante' : ''}'
                          '${active ? '' : ' · ${_pigStates[pig['estado']]}'}',
                        ),
                        onTap: () =>
                            _showPigDetails(context, pig, penName, farrowings),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Acciones del cerdo',
                          onSelected: (action) async {
                            if (action == 'edit') {
                              await _openPigForm(context, pig: pig);
                            } else {
                              await _deletePig(context, ref, pig);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            if (isAdmin)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPigForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar cerdo'),
      ),
    );
  }
}

class _PigForm extends ConsumerStatefulWidget {
  const _PigForm({this.pig});

  final Map<String, dynamic>? pig;

  @override
  ConsumerState<_PigForm> createState() => _PigFormState();
}

class _PigFormState extends ConsumerState<_PigForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _raza = TextEditingController();
  final _peso = TextEditingController();
  String _sexo = 'hembra';
  String _estado = 'activo';
  String? _corral;
  DateTime? _birth;
  late String _arete;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pig = widget.pig;
    _arete =
        pig?['arete'] as String? ??
        PigRepository.nextEarTag(
          (ref.read(pigsProvider).valueOrNull ?? const []).map(
            (row) => row['arete'] as String,
          ),
        );
    if (pig == null) _actualizarAretePrevio();
    if (pig != null) {
      _name.text = pig['nombre'] as String? ?? '';
      _raza.text = pig['raza'] as String? ?? '';
      _peso.text = pig['peso']?.toString() ?? '';
      _sexo = pig['sexo'] as String? ?? 'hembra';
      _estado = pig['estado'] as String? ?? 'activo';
      _corral = pig['corral_id'] as String?;
      final birth = pig['fecha_nacimiento'] as String?;
      _birth = birth == null ? null : DateTime.tryParse(birth);
    }
  }

  /// La lista puede no haber cargado todavía al abrir el formulario, y entonces
  /// mostraba 0001 aunque ya existiera; se consulta el número real a la base.
  Future<void> _actualizarAretePrevio() async {
    try {
      final arete = await ref.read(pigRepositoryProvider).previewNextEarTag();
      if (mounted) setState(() => _arete = arete);
    } catch (_) {
      // Sin conexión se queda el cálculo local; el definitivo se asigna al guardar.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _raza.dispose();
    _peso.dispose();
    super.dispose();
  }

  /// Reglas de negocio que se avisan antes de enviar (la base de datos las
  /// vuelve a validar). Devuelve el mensaje del problema, o null si todo bien.
  String? _businessProblem() {
    final pig = widget.pig;
    if (pig != null && (_sexo != 'hembra' || _estado != 'activo')) {
      final farrowings =
          ref.read(farrowingsProvider).valueOrNull ??
          const <Map<String, dynamic>>[];
      if (pendingFarrowingFor(pig['id'] as String, farrowings) != null) {
        return 'Esta cerda tiene una gestación en curso. Registra el parto o '
            'márcala como fallida antes de cambiar su sexo o estado.';
      }
    }
    final movesIn =
        _estado == 'activo' &&
        _corral != null &&
        (pig == null ||
            pig['corral_id'] != _corral ||
            pig['estado'] != 'activo');
    if (movesIn) {
      final pens = ref.read(pensProvider).valueOrNull ?? const [];
      final pen = pens.where((row) => row['id'] == _corral).firstOrNull;
      if (pen != null) {
        final residents = (ref.read(pigsProvider).valueOrNull ?? const [])
            .where(
              (row) =>
                  row['corral_id'] == _corral &&
                  row['estado'] == 'activo' &&
                  row['id'] != pig?['id'],
            )
            .length;
        final capacity = (pen['capacidad'] as num).toInt();
        if (!penHasRoom(capacity: capacity, activeResidents: residents)) {
          return 'El corral ${pen['nombre']} está lleno '
              '($residents de $capacity). Elige otro corral.';
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _saving) return;
    final problem = _businessProblem();
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final pesoCapturado = _peso.text.trim().isEmpty
        ? null
        : double.parse(_peso.text.replaceAll(',', '.'));
    final aviso = pesoIncoherenteConEdad(
      pesoKg: pesoCapturado,
      nacimiento: _birth,
    );
    if (aviso != null) {
      final guardar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Revisa el peso'),
          content: Text(aviso),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Corregir'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar así'),
            ),
          ],
        ),
      );
      if (guardar != true || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      final repository = ref.read(pigRepositoryProvider);
      final peso = pesoCapturado;
      if (widget.pig == null) {
        final arete = await repository.createPig(
          sexo: _sexo,
          nombre: _name.text,
          raza: _raza.text,
          peso: peso,
          corralId: _corral,
          fechaNacimiento: _birth,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cerdo registrado con arete $arete.')),
          );
        }
      } else {
        await repository.updatePig(
          pigId: widget.pig!['id'] as String,
          sexo: _sexo,
          estado: _estado,
          nombre: _name.text,
          raza: _raza.text,
          peso: peso,
          corralId: _corral,
          fechaNacimiento: _birth,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el cerdo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pens = ref.watch(pensProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.pig == null ? 'Nuevo cerdo' : 'Editar cerdo',
                  style: const TextStyle(fontSize: 22),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tag),
                  title: Text(
                    widget.pig == null
                        ? 'Arete automático (se confirma al guardar)'
                        : 'Arete',
                  ),
                  subtitle: Text(_arete),
                ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cerdo',
                  ),
                ),
                TextFormField(
                  controller: _raza,
                  decoration: const InputDecoration(labelText: 'Raza'),
                ),
                TextFormField(
                  controller: _peso,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  validator: validatePigWeight,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _sexo,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
                    DropdownMenuItem(value: 'macho', child: Text('Macho')),
                  ],
                  onChanged: (v) => setState(() => _sexo = v!),
                ),
                if (widget.pig != null)
                  DropdownButtonFormField<String>(
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      for (final state in _pigStates.entries)
                        DropdownMenuItem(
                          value: state.key,
                          child: Text(state.value),
                        ),
                    ],
                    onChanged: (v) => setState(() => _estado = v!),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _birth == null
                        ? 'Fecha de nacimiento'
                        : 'Nacimiento: ${DateFormat.yMMMd('es').format(_birth!)}',
                  ),
                  subtitle: _sexo == 'hembra' && _birth == null
                      ? const Text('Necesaria para registrar inseminaciones')
                      : null,
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: _birth ?? DateTime.now(),
                    );
                    if (d != null) setState(() => _birth = d);
                  },
                ),
                pens.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => ErrorView(
                    compact: true,
                    title: 'No se pudieron cargar los corrales',
                    error: error,
                    onRetry: () => ref.invalidate(pensProvider),
                  ),
                  data: (rows) => DropdownButtonFormField<String?>(
                    initialValue: rows.any((pen) => pen['id'] == _corral)
                        ? _corral
                        : null,
                    decoration: const InputDecoration(labelText: 'Corral'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin corral'),
                      ),
                      for (final pen in rows)
                        DropdownMenuItem<String?>(
                          value: pen['id'] as String,
                          child: Text(pen['nombre'] as String),
                        ),
                    ],
                    onChanged: (value) => setState(() => _corral = value),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.pig == null ? 'Guardar' : 'Guardar cambios',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
