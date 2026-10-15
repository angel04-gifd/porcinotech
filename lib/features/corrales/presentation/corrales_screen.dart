import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../alimentos/data/feed_plan.dart';
import '../../alimentos/data/production_stage_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../cerdos/data/pig_repository.dart';
import '../../partos/data/farrowing_repository.dart';
import '../data/pen_repository.dart';

class CorralesScreen extends ConsumerWidget {
  const CorralesScreen({super.key});

  Color _color(String state) => switch (state) {
    'mantenimiento' => Colors.amber,
    'alerta' => Colors.red,
    _ => Colors.green,
  };

  Future<void> _showPenDetails(
    BuildContext context,
    Map<String, dynamic> pen,
    List<Map<String, dynamic>> pigs,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PenDetails(pen: pen, pigs: pigs),
  );

  Future<void> _openPenForm(
    BuildContext context, {
    Map<String, dynamic>? pen,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PenForm(pen: pen),
  );

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String errorPrefix,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$errorPrefix: $error')));
      }
    }
  }

  Future<void> _deletePen(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> pen,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar corral'),
        content: Text(
          '¿Eliminar ${pen['nombre']}? Sus cerdos quedarán sin corral asignado.',
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
    await _run(
      context,
      () => ref.read(penRepositoryProvider).deletePen(pen['id'] as String),
      'No se pudo eliminar el corral',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pensState = ref.watch(pensProvider);
    final pigsState = ref.watch(pigsProvider);
    final stageNames = {
      for (final stage
          in ref.watch(productionStagesProvider).valueOrNull ??
              <Map<String, dynamic>>[])
        stage['etapa'] as String: stage['nombre'] as String,
    };
    final isAdmin = ref.watch(currentUserRoleProvider).valueOrNull == 'admin';
    return Scaffold(
      body: pensState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('No se pudieron cargar los corrales: $error')),
        data: (pens) => pigsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('No se pudo cargar la ocupación: $error')),
          data: (allPigs) {
            final pigs = allPigs.where(isActivePig).toList();
            if (pens.isEmpty) {
              return Center(
                child: Text(
                  isAdmin
                      ? 'No hay corrales registrados. Usa "Nuevo corral".'
                      : 'No hay corrales registrados. Pide al administrador que los cree.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: pens.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final pen = pens[index];
                final residents = pigs
                    .where((pig) => pig['corral_id'] == pen['id'])
                    .length;
                final capacity = (pen['capacidad'] as num).toInt();
                final overCapacity = residents > capacity;
                final color = overCapacity
                    ? Colors.red
                    : _color(pen['estado'] as String);
                final stage = pen['etapa'] as String? ?? 'desarrollo';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        '$residents',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(pen['nombre'] as String),
                    subtitle: Text(
                      '$residents/$capacity cerdos · ${stageNames[stage] ?? stage}\n'
                      'Estado: ${pen['estado']}${overCapacity ? ' · SOBRECARGADO' : ''}',
                      style: TextStyle(color: overCapacity ? Colors.red : null),
                    ),
                    isThreeLine: true,
                    onTap: () => _showPenDetails(context, pen, pigs),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Acciones del corral',
                      onSelected: (action) {
                        if (action.startsWith('estado:')) {
                          _run(
                            context,
                            () => ref
                                .read(penRepositoryProvider)
                                .updatePenState(
                                  penId: pen['id'] as String,
                                  state: action.substring('estado:'.length),
                                ),
                            'No se pudo cambiar el estado',
                          );
                        } else if (action == 'edit') {
                          _openPenForm(context, pen: pen);
                        } else if (action == 'delete') {
                          _deletePen(context, ref, pen);
                        }
                      },
                      itemBuilder: (_) => [
                        for (final state in const {
                          'normal': 'Estado: Normal',
                          'mantenimiento': 'Estado: Mantenimiento',
                          'alerta': 'Estado: Alerta',
                        }.entries)
                          PopupMenuItem(
                            value: 'estado:${state.key}',
                            child: Text(state.value),
                          ),
                        if (isAdmin) ...[
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar corral'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar corral'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openPenForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo corral'),
            )
          : null,
    );
  }
}

class _PenDetails extends ConsumerWidget {
  const _PenDetails({required this.pen, required this.pigs});

  final Map<String, dynamic> pen;
  final List<Map<String, dynamic>> pigs;

  String _gestation(
    Map<String, dynamic> pig,
    List<Map<String, dynamic>> farrowings,
  ) {
    if (pig['sexo'] != 'hembra') return 'Macho';
    final pending = pendingFarrowingFor(pig['id'] as String, farrowings);
    if (pending == null) return 'No gestante';
    final mating = DateTime.parse(pending['fecha_monta'] as String);
    final due = DateTime.parse(pending['fecha_estimada_parto'] as String);
    final day = DateUtils.dateOnly(DateTime.now()).difference(mating).inDays;
    return 'Gestante · día $day de $gestationDays · parto ${DateFormat.yMMMd('es').format(due)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farrowings =
        ref.watch(farrowingsProvider).valueOrNull ?? <Map<String, dynamic>>[];
    final residents = pigs
        .where((pig) => pig['corral_id'] == pen['id'])
        .toList();
    final capacity = (pen['capacidad'] as num).toInt();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                pen['nombre'] as String,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                'Ocupación ${residents.length}/$capacity'
                '${residents.length > capacity ? ' · supera su capacidad' : ''}',
              ),
            ),
            const Divider(height: 1),
            if (residents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay cerdos activos en este corral.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: residents.length,
                  itemBuilder: (context, index) {
                    final pig = residents[index];
                    return ListTile(
                      leading: Icon(
                        pig['sexo'] == 'hembra' ? Icons.female : Icons.male,
                      ),
                      title: Text(
                        'Arete ${pig['arete']} · ${pig['nombre'] ?? 'Sin nombre'}',
                      ),
                      subtitle: Text(_gestation(pig, farrowings)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PenForm extends ConsumerStatefulWidget {
  const _PenForm({this.pen});

  final Map<String, dynamic>? pen;

  @override
  ConsumerState<_PenForm> createState() => _PenFormState();
}

class _PenFormState extends ConsumerState<_PenForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _capacity;
  late final TextEditingController _location;
  late String _stage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pen = widget.pen;
    _name = TextEditingController(text: pen?['nombre'] as String? ?? '');
    _capacity = TextEditingController(
      text: pen?['capacidad']?.toString() ?? '',
    );
    _location = TextEditingController(text: pen?['ubicacion'] as String? ?? '');
    _stage = pen?['etapa'] as String? ?? 'desarrollo';
  }

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final repository = ref.read(penRepositoryProvider);
      if (widget.pen == null) {
        await repository.createPen(
          nombre: _name.text,
          capacidad: int.parse(_capacity.text),
          etapa: _stage,
          ubicacion: _location.text,
        );
      } else {
        await repository.updatePen(
          penId: widget.pen!['id'] as String,
          nombre: _name.text,
          capacidad: int.parse(_capacity.text),
          etapa: _stage,
          ubicacion: _location.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el corral: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = ref.watch(productionStagesProvider);
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
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.pen == null ? 'Nuevo corral' : 'Editar corral',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                TextFormField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacidad'),
                  validator: (value) {
                    final capacity = int.tryParse(value ?? '');
                    return capacity != null && capacity > 0
                        ? null
                        : 'Ingresa una capacidad mayor que cero';
                  },
                ),
                stages.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: LinearProgressIndicator(),
                  ),
                  error: (error, _) => Text(
                    'No se cargaron las etapas. ¿Ejecutaste la migración 20260930? $error',
                  ),
                  data: (rows) => DropdownButtonFormField<String>(
                    initialValue: rows.any((stage) => stage['etapa'] == _stage)
                        ? _stage
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Etapa productiva del corral',
                    ),
                    items: [
                      for (final stage in rows)
                        DropdownMenuItem<String>(
                          value: stage['etapa'] as String,
                          child: Text(
                            '${stage['nombre']} · ${stage['racion_sugerida_kg_por_cerdo_dia']} kg/cerdo/día',
                          ),
                        ),
                    ],
                    validator: (value) => value == null
                        ? 'Selecciona una etapa productiva'
                        : null,
                    onChanged: (value) => setState(() {
                      if (value != null) _stage = value;
                    }),
                  ),
                ),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación (opcional)',
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
                      : const Text('Guardar corral'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
