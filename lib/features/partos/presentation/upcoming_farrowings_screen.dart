import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/error_view.dart';
import '../../auth/data/auth_repository.dart';
import '../../cerdos/data/pig_repository.dart';
import '../data/farrowing_repository.dart';

/// Cerdas gestantes (sin parto real registrado), incluidas las vencidas.
class UpcomingFarrowingsScreen extends ConsumerWidget {
  const UpcomingFarrowingsScreen({super.key});

  Future<void> _deleteFarrowing(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> farrowing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Eliminar esta inseminación y su parto estimado?'),
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
      await ref
          .read(farrowingRepositoryProvider)
          .deleteFarrowing(farrowing['id'] as String);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farrowings = ref.watch(farrowingsProvider);
    final pigs = ref.watch(pigsProvider);
    final isAdmin = ref.watch(currentUserRoleProvider).valueOrNull == 'admin';
    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximos partos'),
        actions: [
          IconButton(
            tooltip: 'Abrir calendario',
            onPressed: () => context.go('/partos'),
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: farrowings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          title: 'No se pudieron cargar los partos',
          error: error,
          onRetry: () => ref.invalidate(farrowingsProvider),
        ),
        data: (rows) => pigs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            title: 'No se pudieron cargar las cerdas',
            error: error,
            onRetry: () => ref.invalidate(pigsProvider),
          ),
          data: (pigRows) {
            final pigsById = {
              for (final pig in pigRows) pig['id'] as String: pig,
            };
            final upcoming =
                rows.where(isPendingFarrowing).toList()..sort(
                  (a, b) => (a['fecha_estimada_parto'] as String).compareTo(
                    b['fecha_estimada_parto'] as String,
                  ),
                );

            if (upcoming.isEmpty) {
              return const Center(
                child: Text('No hay cerdas gestantes registradas.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: upcoming.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final birth = upcoming[index];
                final sow = pigsById[birth['cerda_id']];
                final dueDate = DateTime.parse(
                  birth['fecha_estimada_parto'] as String,
                );
                final matingDate = DateTime.parse(
                  birth['fecha_monta'] as String,
                );
                final observations = (birth['observaciones'] as String?)
                    ?.trim();
                final daysLeft = dueDate.difference(today).inDays;
                final overdue = daysLeft < 0;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: overdue
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      child: Text(overdue ? '!' : '$daysLeft'),
                    ),
                    title: Text(
                      sow == null
                          ? 'Cerda ${birth['cerda_id']}'
                          : 'Arete ${sow['arete']} · ${sow['nombre'] ?? 'Sin nombre'}',
                    ),
                    subtitle: Text(
                      'Inseminación ${DateFormat.yMMMd('es').format(matingDate)}\n'
                      'Parto estimado ${DateFormat.yMMMd('es').format(dueDate)} · '
                      '${overdue ? 'vencido hace ${-daysLeft} días' : 'faltan $daysLeft días'}'
                      '${observations == null || observations.isEmpty ? '' : '\n$observations'}',
                    ),
                    isThreeLine: true,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _BirthForm(farrowing: birth),
                    ),
                    trailing: isAdmin
                        ? IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _deleteFarrowing(context, ref, birth),
                          )
                        : const Icon(Icons.edit_note),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BirthForm extends ConsumerStatefulWidget {
  const _BirthForm({required this.farrowing});

  final Map<String, dynamic> farrowing;

  @override
  ConsumerState<_BirthForm> createState() => _BirthFormState();
}

class _BirthFormState extends ConsumerState<_BirthForm> {
  final _formKey = GlobalKey<FormState>();
  final _born = TextEditingController();
  final _alive = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _saving = false;

  @override
  void dispose() {
    _born.dispose();
    _alive.dispose();
    super.dispose();
  }

  Future<void> _markFailed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestación fallida'),
        content: const Text(
          '¿La cerda no llegó a parir (aborto o monta sin preñez)? '
          'Quedará disponible para una nueva inseminación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Marcar como fallida'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(farrowingRepositoryProvider)
          .markFailed(widget.farrowing['id'] as String);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(farrowingRepositoryProvider)
          .registerBirth(
            farrowingId: widget.farrowing['id'] as String,
            birthDate: _date,
            bornPiglets: int.parse(_born.text),
            livePiglets: int.parse(_alive.text),
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar el parto: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matingDate = DateTime.parse(
      widget.farrowing['fecha_monta'] as String,
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final earliest = earliestBirthDate(matingDate);
    final tooEarly = earliest.isAfter(today);
    if (_date.isBefore(earliest) && !tooEarly) _date = earliest;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registrar parto real',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (tooEarly)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aún no se puede registrar el parto: la gestación dura al '
                    'menos $minGestationDays días (desde el '
                    '${DateFormat.yMMMd('es').format(earliest)}). '
                    'Si la cerda no llegó a parir, márcala como fallida.',
                  ),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha del parto'),
                  subtitle: Text(DateFormat.yMMMMd('es').format(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: earliest,
                      lastDate: today,
                    );
                    if (selected != null) setState(() => _date = selected);
                  },
                ),
              TextFormField(
                controller: _born,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lechones nacidos',
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  return number == null || number < 0
                      ? 'Ingresa un número válido'
                      : null;
                },
              ),
              TextFormField(
                controller: _alive,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lechones vivos'),
                validator: (value) {
                  final alive = int.tryParse(value ?? '');
                  final born = int.tryParse(_born.text);
                  if (alive == null || alive < 0) {
                    return 'Ingresa un número válido';
                  }
                  if (born != null && alive > born) {
                    return 'No puede superar a los nacidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving || tooEarly ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar parto'),
              ),
              TextButton(
                onPressed: _saving ? null : _markFailed,
                child: const Text('La gestación no prosperó'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
