import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../cerdos/data/pig_repository.dart';
import '../data/farrowing_repository.dart';

class PartosScreen extends ConsumerStatefulWidget {
  const PartosScreen({super.key});
  @override
  ConsumerState<PartosScreen> createState() => _PartosScreenState();
}

class _PartosScreenState extends ConsumerState<PartosScreen> {
  DateTime? _mating;
  String? _sow;
  DateTime? _sowBirthDate;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedCalendarDay;
  final _observations = TextEditingController();
  bool _saving = false;
  // Cambia tras guardar para reconstruir el selector de cerda vacío.
  int _formVersion = 0;
  DateTime? get _fepa => _mating == null ? null : dueDateFor(_mating!);

  Future<void> _jumpToCalendarDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _selectedCalendarDay ?? _calendarMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Ir a una fecha del calendario',
    );
    if (chosen != null) {
      setState(() {
        _calendarMonth = DateTime(chosen.year, chosen.month);
        _selectedCalendarDay = chosen;
      });
    }
  }

  Future<void> _selectMatingDate() async {
    final birthDate = _sowBirthDate;
    if (birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa la fecha de nacimiento de la cerda antes de registrar la inseminación.',
          ),
        ),
      );
      return;
    }
    final firstDate = birthDate;
    final today = DateUtils.dateOnly(DateTime.now());
    if (firstDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de nacimiento de la cerda no puede estar en el futuro.',
          ),
        ),
      );
      return;
    }
    final initialDate = _mating != null && !_mating!.isBefore(firstDate)
        ? _mating!
        : today;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'Selecciona la fecha de inseminación',
    );
    if (selected != null) setState(() => _mating = selected);
  }

  @override
  void dispose() {
    _observations.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_mating == null || _sow == null || _saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la cerda y la fecha de monta.'),
        ),
      );
      return;
    }
    if (_sowBirthDate == null || _mating!.isBefore(_sowBirthDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La inseminación no puede ser anterior al nacimiento de la cerda. Completa y verifica esa fecha.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(farrowingRepositoryProvider)
          .createFarrowing(
            sowId: _sow!,
            matingDate: _mating!,
            observations: _observations.text,
          );
      if (mounted) {
        setState(() {
          _mating = null;
          _sow = null;
          _sowBirthDate = null;
          _formVersion++;
          _observations.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inseminación registrada.')),
        );
      }
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

  Widget _buildCalendar(
    AsyncValue<List<Map<String, dynamic>>> farrowings,
    AsyncValue<List<Map<String, dynamic>>> pigs,
  ) => farrowings.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('No se pudo cargar el calendario: $error'),
    data: (rows) {
      final pigsById = {
        for (final pig in pigs.valueOrNull ?? <Map<String, dynamic>>[])
          pig['id'] as String: pig,
      };
      final events = <DateTime, List<String>>{};
      for (final row in rows) {
        final pig = pigsById[row['cerda_id']];
        final earTag = pig == null ? 'cerda' : 'arete ${pig['arete']}';
        final observations = (row['observaciones'] as String?)?.trim();
        final details = observations == null || observations.isEmpty
            ? ''
            : ' · $observations';
        final matingDate = DateTime.parse(row['fecha_monta'] as String);
        events.update(
          DateTime(matingDate.year, matingDate.month, matingDate.day),
          (descriptions) => [...descriptions, 'Inseminación de $earTag'],
          ifAbsent: () => ['Inseminación de $earTag'],
        );
        // Una gestación fallida ya no tiene parto estimado ni parto real.
        if (row['fallida'] == true) continue;
        final dueDate = DateTime.parse(row['fecha_estimada_parto'] as String);
        final normalizedDueDate = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
        );
        events.update(
          normalizedDueDate,
          (descriptions) => [
            ...descriptions,
            'Parto estimado de $earTag$details',
          ],
          ifAbsent: () => ['Parto estimado de $earTag$details'],
        );
        final actualDateValue = row['fecha_parto'] as String?;
        if (actualDateValue != null) {
          final actualDate = DateTime.parse(actualDateValue);
          final normalizedActualDate = DateTime(
            actualDate.year,
            actualDate.month,
            actualDate.day,
          );
          events.update(
            normalizedActualDate,
            (descriptions) => [
              ...descriptions,
              'Parto registrado de $earTag$details',
            ],
            ifAbsent: () => ['Parto registrado de $earTag$details'],
          );
        }
      }

      final monthStart = DateTime(_calendarMonth.year, _calendarMonth.month);
      final dayCount = DateUtils.getDaysInMonth(
        _calendarMonth.year,
        _calendarMonth.month,
      );
      final leadingDays = monthStart.weekday - DateTime.monday;
      final selected = _selectedCalendarDay ?? DateTime.now();
      final selectedEvents = events.entries
          .where((entry) => DateUtils.isSameDay(entry.key, selected))
          .expand((entry) => entry.value)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Mes anterior',
                        onPressed: () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month - 1,
                          );
                        }),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: TextButton.icon(
                            onPressed: _jumpToCalendarDate,
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: Text(
                              toBeginningOfSentenceCase(
                                    DateFormat.yMMMM(
                                      'es',
                                    ).format(_calendarMonth),
                                  ) ??
                                  DateFormat.yMMMM('es').format(_calendarMonth),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mes siguiente',
                        onPressed: () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month + 1,
                          );
                        }),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  Row(
                    children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(day),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leadingDays + dayCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisExtent: 46,
                        ),
                    itemBuilder: (context, index) {
                      if (index < leadingDays) return const SizedBox.shrink();
                      final date = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month,
                        index - leadingDays + 1,
                      );
                      final hasEvent = events.keys.any(
                        (eventDate) => DateUtils.isSameDay(eventDate, date),
                      );
                      final isSelected = DateUtils.isSameDay(selected, date);
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () =>
                            setState(() => _selectedCalendarDay = date),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 4,
                              child: hasEvent
                                  ? Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat.yMMMMd('es').format(selected),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (selectedEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No hay eventos para este día.'),
                      ),
                    )
                  else
                    ...selectedEvents.map(
                      (description) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          description.startsWith('Inseminación')
                              ? Icons.water_drop_outlined
                              : Icons.event_available,
                        ),
                        title: Text(description),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final farrowings = ref.watch(farrowingsProvider);
    final pigs = ref.watch(pigsProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Calendario de partos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/partos/proximos'),
              icon: const Icon(Icons.list_alt),
              label: const Text('Próximos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCalendar(farrowings, pigs),
        const SizedBox(height: 20),
        Text(
          'Registrar inseminación',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        pigs.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('No se pudieron cargar las cerdas: $error'),
          data: (pigs) {
            final farrowingRows =
                farrowings.valueOrNull ?? <Map<String, dynamic>>[];
            // Una cerda gestante no puede inseminarse de nuevo hasta registrar su parto.
            final sows = pigs
                .where(
                  (pig) =>
                      pig['sexo'] == 'hembra' &&
                      pig['estado'] == 'activo' &&
                      pendingFarrowingFor(pig['id'] as String, farrowingRows) ==
                          null,
                )
                .toList();
            if (sows.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No hay cerdas activas disponibles. Registra hembras en Cerdos o espera a que las gestantes paran.',
                ),
              );
            }
            return DropdownButtonFormField<String>(
              key: ValueKey(_formVersion),
              initialValue: _sow,
              decoration: const InputDecoration(labelText: 'Cerda'),
              items: sows
                  .map<DropdownMenuItem<String>>(
                    (pig) => DropdownMenuItem<String>(
                      value: pig['id'] as String,
                      child: Text(
                        'Arete ${pig['arete']} · ${pig['nombre'] ?? pig['raza'] ?? 'Sin nombre'}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _sow = value;
                final selectedSow = sows.where((pig) => pig['id'] == value);
                final birthDate = selectedSow.isEmpty
                    ? null
                    : selectedSow.first['fecha_nacimiento'] as String?;
                _sowBirthDate = birthDate == null
                    ? null
                    : DateTime.tryParse(birthDate);
                if (_mating != null &&
                    _sowBirthDate != null &&
                    _mating!.isBefore(_sowBirthDate!)) {
                  _mating = null;
                }
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fecha de inseminación / monta'),
          subtitle: Text(
            _mating == null
                ? _sowBirthDate == null
                      ? 'Completa primero el nacimiento en Cerdos'
                      : 'Desde ${DateFormat.yMMMd('es').format(_sowBirthDate!)}'
                : DateFormat.yMMMMd('es').format(_mating!),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _sow == null ? null : _selectMatingDate,
        ),
        if (_fepa != null)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Fecha Estimada de Parto (FEPA)'),
              subtitle: Text(DateFormat.yMMMMd('es').format(_fepa!)),
            ),
          ),
        TextField(
          controller: _observations,
          maxLines: 2,
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
              : const Text('Guardar inseminación'),
        ),
      ],
    );
  }
}
