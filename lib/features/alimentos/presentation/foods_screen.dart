import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/error_view.dart';
import '../../auth/data/auth_repository.dart';
import '../data/feed_plan.dart';
import '../data/food_repository.dart';
import '../data/production_stage_repository.dart';

class FoodsScreen extends ConsumerWidget {
  const FoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foods = ref.watch(foodsProvider);
    final plan = ref.watch(feedPlanProvider).valueOrNull;
    final stages = {
      for (final stage
          in ref.watch(productionStagesProvider).valueOrNull ??
              <Map<String, dynamic>>[])
        stage['etapa'] as String: stage['nombre'] as String,
    };
    final feedRecords = ref.watch(feedRecordsProvider).valueOrNull ?? [];
    final today = _dateKey(DateTime.now());
    final canManageFoods =
        ref.watch(currentUserRoleProvider).valueOrNull == 'admin';

    return Scaffold(
      body: foods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          title: 'No se pudieron cargar los alimentos',
          error: error,
          onRetry: () => ref.invalidate(foodsProvider),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Text(
                  canManageFoods
                      ? 'No hay alimentos registrados. Usa "Agregar alimento".'
                      : 'No hay alimentos registrados. Pide al administrador que los agregue.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final food = items[index];
                  final stage = food['etapa'] as String?;
                  final stock = (food['existencia_kg'] as num).toDouble();
                  final dailyNeed = plan?.dailyKgForStage(stage) ?? 0;
                  final daysLeft = dailyNeed == 0 ? null : stock / dailyNeed;
                  final consumedToday = feedRecords
                      .where(
                        (record) =>
                            record['alimento_id'] == food['id'] &&
                            record['fecha'] == today,
                      )
                      .fold<double>(
                        0,
                        (sum, record) =>
                            sum +
                            ((record['cantidad_kg'] as num?)?.toDouble() ?? 0),
                      );

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.grass_outlined),
                            ),
                            title: Text(food['nombre'] as String),
                            subtitle: Text(
                              '${food['tipo'] ?? 'Alimento'} · ${stage == null ? 'Todas las etapas' : stages[stage] ?? stage}',
                            ),
                            trailing: canManageFoods
                                ? PopupMenuButton<String>(
                                    tooltip: 'Acciones del alimento',
                                    onSelected: (action) async {
                                      if (action == 'edit') {
                                        await _showFoodForm(
                                          context,
                                          food: food,
                                        );
                                      } else {
                                        await _confirmDelete(
                                          context,
                                          ref,
                                          food,
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar alimento / stock'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _InventoryStat(
                                  label: 'Existencia',
                                  value: '${stock.toStringAsFixed(1)} kg',
                                ),
                              ),
                              Expanded(
                                child: _InventoryStat(
                                  label: 'Ración diaria',
                                  value:
                                      '${dailyNeed.toStringAsFixed(1)} kg/día',
                                ),
                              ),
                              Expanded(
                                child: _InventoryStat(
                                  label: 'Cobertura',
                                  value: daysLeft == null
                                      ? 'Sin cerdos'
                                      : '${daysLeft.toStringAsFixed(1)} días',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Consumo registrado hoy: ${consumedToday.toStringAsFixed(1)} kg',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: () =>
                                  _showConsumptionForm(context, food: food),
                              icon: const Icon(Icons.restaurant),
                              label: const Text('Registrar consumo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: canManageFoods
          ? FloatingActionButton.extended(
              onPressed: () => _showFoodForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar alimento'),
            )
          : null,
    );
  }

  Future<void> _showFoodForm(
    BuildContext context, {
    Map<String, dynamic>? food,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FoodForm(food: food),
  );

  Future<void> _showConsumptionForm(
    BuildContext context, {
    required Map<String, dynamic> food,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ConsumptionForm(food: food),
  );

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> food,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar alimento'),
        content: Text(
          '¿Eliminar ${food['nombre']}? Si tiene consumos registrados, Supabase impedirá eliminarlo para conservar el historial.',
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
      await ref.read(foodRepositoryProvider).deleteFood(food['id'] as String);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _InventoryStat extends StatelessWidget {
  const _InventoryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      Text(value, style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({this.food});

  final Map<String, dynamic>? food;

  @override
  ConsumerState<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _stock;
  late final TextEditingController _cost;
  String? _stage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final food = widget.food;
    _name = TextEditingController(text: food?['nombre'] as String? ?? '');
    _type = TextEditingController(text: food?['tipo'] as String? ?? '');
    _stock = TextEditingController(
      text: food?['existencia_kg']?.toString() ?? '',
    );
    _cost = TextEditingController(
      text: (food?['costo_por_kg'] ?? 0).toString(),
    );
    _stage = food?['etapa'] as String?;
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _stock.dispose();
    _cost.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _nonNegative(String? value) {
    final number = _number(value ?? '');
    return number == null || number < 0
        ? 'Ingresa cero o un valor positivo'
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final repository = ref.read(foodRepositoryProvider);
      final stock = _number(_stock.text)!;
      final cost = _number(_cost.text)!;
      if (widget.food == null) {
        await repository.createFood(
          nombre: _name.text,
          tipo: _type.text,
          existenciaKg: stock,
          etapa: _stage,
          costoPorKg: cost,
        );
      } else {
        await repository.updateFood(
          foodId: widget.food!['id'] as String,
          nombre: _name.text,
          tipo: _type.text,
          existenciaKg: stock,
          etapa: _stage,
          costoPorKg: cost,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el alimento: $error')),
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
                  widget.food == null ? 'Agregar alimento' : 'Editar alimento',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre'
                      : null,
                ),
                TextFormField(
                  controller: _type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo (opcional)',
                  ),
                ),
                stages.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) =>
                      Text('No se cargaron las etapas: $error'),
                  data: (rows) => DropdownButtonFormField<String?>(
                    initialValue: _stage,
                    decoration: const InputDecoration(
                      labelText: 'Etapa productiva',
                      helperText:
                          'La ración diaria se calcula con los corrales de esta etapa.',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas las etapas'),
                      ),
                      for (final stage in rows)
                        DropdownMenuItem<String?>(
                          value: stage['etapa'] as String,
                          child: Text(
                            '${stage['nombre']} · ${stage['racion_sugerida_kg_por_cerdo_dia']} kg/cerdo',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _stage = value),
                  ),
                ),
                TextFormField(
                  controller: _stock,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Existencia (kg)',
                  ),
                  validator: _nonNegative,
                ),
                TextFormField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Costo por kg (opcional)',
                  ),
                  validator: _nonNegative,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsumptionForm extends ConsumerStatefulWidget {
  const _ConsumptionForm({required this.food});

  final Map<String, dynamic> food;

  @override
  ConsumerState<_ConsumptionForm> createState() => _ConsumptionFormState();
}

class _ConsumptionFormState extends ConsumerState<_ConsumptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _observations = TextEditingController();
  DateTime _date = DateTime.now();
  String? _penId;
  bool _prefilled = false;
  bool _saving = false;

  String? get _stage => widget.food['etapa'] as String?;

  @override
  void dispose() {
    _quantity.dispose();
    _observations.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  void _suggest(FeedPlan plan) {
    final pens = plan.pensForStage(_stage);
    final kg = _penId == null
        ? plan.dailyKgForStage(_stage)
        : pens
              .where((pen) => pen.penId == _penId)
              .fold<double>(0, (sum, pen) => sum + pen.dailyKg);
    _quantity.text = kg.toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(foodRepositoryProvider)
          .recordConsumption(
            foodId: widget.food['id'] as String,
            quantityKg: _number(_quantity.text)!,
            date: _date,
            penId: _penId,
            observations: _observations.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar el consumo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = (widget.food['existencia_kg'] as num).toDouble();
    final plan = ref.watch(feedPlanProvider).valueOrNull;
    if (plan != null && !_prefilled) {
      _prefilled = true;
      _suggest(plan);
    }
    final pens = plan?.pensForStage(_stage) ?? const <PenFeedNeed>[];

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
                  'Consumo: ${widget.food['nombre']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('Stock disponible: ${stock.toStringAsFixed(2)} kg'),
                if (plan == null)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String?>(
                    initialValue: _penId,
                    decoration: const InputDecoration(labelText: 'Corral'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Todos (${plan.dailyKgForStage(_stage).toStringAsFixed(1)} kg)',
                        ),
                      ),
                      for (final pen in pens)
                        DropdownMenuItem<String?>(
                          value: pen.penId,
                          child: Text(
                            '${pen.penName} · ${pen.pigCount} × ${pen.rationPerPig} = ${pen.dailyKg.toStringAsFixed(1)} kg',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _penId = value;
                      _suggest(plan);
                    }),
                  ),
                TextFormField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cantidad consumida (kg)',
                    helperText: 'Calculada automáticamente; puedes ajustarla.',
                  ),
                  validator: (value) {
                    final quantity = _number(value ?? '');
                    if (quantity == null || quantity <= 0) {
                      return 'Ingresa una cantidad válida';
                    }
                    if (quantity > stock) {
                      return 'La cantidad supera el stock disponible';
                    }
                    return null;
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha'),
                  subtitle: Text(DateFormat.yMMMMd('es').format(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) setState(() => _date = selected);
                  },
                ),
                TextField(
                  controller: _observations,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
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
                      : const Text('Registrar consumo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
