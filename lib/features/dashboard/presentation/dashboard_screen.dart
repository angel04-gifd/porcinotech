import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/error_view.dart';
import '../../alimentos/data/feed_plan.dart';
import '../../alimentos/data/food_repository.dart';
import '../../alimentos/data/production_stage_repository.dart';
import 'consumption_chart.dart';
import 'weather_card.dart';
import '../../cerdos/data/pig_repository.dart';
import '../../corrales/data/pen_repository.dart';
import '../../dashboard/data/consumption_repository.dart';
import '../../partos/data/farrowing_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pigs = ref.watch(pigsProvider);
    final pens = ref.watch(pensProvider);
    final farrowings = ref.watch(farrowingsProvider);
    final consumption = ref.watch(todayConsumptionProvider);
    final feedRecords = ref.watch(feedRecordsProvider);
    final foods = ref.watch(foodsProvider);
    final feedPlan = ref.watch(feedPlanProvider);
    final stageNames = {
      for (final stage
          in ref.watch(productionStagesProvider).valueOrNull ??
              <Map<String, dynamic>>[])
        stage['etapa'] as String: stage['nombre'] as String,
    };
    final activePigs = pigs.whenData((rows) => rows.where(isActivePig).length);
    // Un corral está ocupado si tiene al menos un cerdo activo.
    final occupiedPens = pens.whenData((penRows) {
      final occupiedIds = {
        for (final pig in pigs.valueOrNull ?? <Map<String, dynamic>>[])
          if (isActivePig(pig)) pig['corral_id'],
      };
      return penRows.where((pen) => occupiedIds.contains(pen['id'])).length;
    });
    final upcomingBirths = farrowings.whenData(
      (rows) => rows.where(isPendingFarrowing).length,
    );
    final metrics = [
      (
        'Cerdos activos',
        _metricValue(activePigs, (value) => value.toString()),
        Icons.pets,
      ),
      (
        'Corrales ocupados',
        _metricValue(occupiedPens, (value) => value.toString()),
        Icons.grid_view,
      ),
      (
        'Consumo hoy',
        '${_metricValue(consumption, (value) => value.toStringAsFixed(1))} kg',
        Icons.restaurant,
      ),
      (
        'Próximos partos',
        _metricValue(upcomingBirths, (value) => value.toString()),
        Icons.favorite,
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pigsProvider);
        ref.invalidate(pensProvider);
        ref.invalidate(farrowingsProvider);
        ref.invalidate(todayConsumptionProvider);
        ref.invalidate(feedRecordsProvider);
        ref.invalidate(foodsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Resumen de la granja',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: metrics.length,
              itemBuilder: (_, i) {
                final metric = metrics[i];
                const destinations = [
                  '/cerdos',
                  '/corrales',
                  '/alimentos',
                  '/partos/proximos',
                ];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go(destinations[i]),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(metric.$3),
                          const Spacer(),
                          Text(
                            metric.$2,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(metric.$1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const WeatherCard(),
          const SizedBox(height: 12),
          _buildFeedBalance(
            context,
            foods,
            feedPlan,
            onRetry: () => ref.invalidate(foodsProvider),
          ),
          const SizedBox(height: 12),
          _buildConsumptionChart(
            context,
            feedRecords,
            foods,
            stageNames,
            onRetry: () => ref.invalidate(feedRecordsProvider),
          ),
          const SizedBox(height: 12),
          _buildUpcomingBirths(
            context,
            farrowings,
            pigs,
            onRetry: () => ref.invalidate(farrowingsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBalance(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> foods,
    AsyncValue<FeedPlan> feedPlan, {
    required VoidCallback onRetry,
  }) => foods.when(
    loading: () => const LinearProgressIndicator(),
    error: (error, _) => Card(
      child: ErrorView(
        compact: true,
        title: 'No se pudo calcular el balance',
        error: error,
        onRetry: onRetry,
      ),
    ),
    data: (rows) {
      final stock = rows.fold<double>(
        0,
        (sum, food) => sum + ((food['existencia_kg'] as num?)?.toDouble() ?? 0),
      );
      final plan = feedPlan.valueOrNull;
      final dailyNeed = plan?.totalDailyKg ?? 0;
      final coverage = dailyNeed == 0 ? null : stock / dailyNeed;
      final unassigned = plan?.unassignedPigs ?? 0;
      return Card(
        child: ListTile(
          leading: const Icon(Icons.balance),
          title: const Text('Balance de alimento'),
          subtitle: Text(
            '${stock.toStringAsFixed(1)} kg disponibles · ${dailyNeed.toStringAsFixed(1)} kg/día según la etapa de cada corral · ${coverage == null ? 'sin consumo estimado' : '${coverage.toStringAsFixed(1)} días de cobertura'}'
            '${unassigned == 0 ? '' : '\n$unassigned cerdos sin corral no se incluyen'}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/alimentos'),
        ),
      );
    },
  );

  Widget _buildConsumptionChart(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> records,
    AsyncValue<List<Map<String, dynamic>>> foods,
    Map<String, String> stageNames, {
    required VoidCallback onRetry,
  }) => records.when(
    loading: () => const Card(
      child: SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
    error: (error, _) => Card(
      child: ErrorView(
        compact: true,
        title: 'No se pudo cargar el consumo',
        error: error,
        onRetry: onRetry,
      ),
    ),
    data: (rows) {
      final theme = Theme.of(context);
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consumo por etapa', style: theme.textTheme.titleMedium),
              Text(
                'Kilogramos registrados, últimos 7 días · toca una barra',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ConsumptionByStageChart(
                records: rows,
                foods: foods.valueOrNull ?? const [],
                stageNames: stageNames,
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildUpcomingBirths(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> farrowings,
    AsyncValue<List<Map<String, dynamic>>> pigs, {
    required VoidCallback onRetry,
  }) => farrowings.when(
    loading: () => const LinearProgressIndicator(),
    error: (error, _) => Card(
      child: ErrorView(
        compact: true,
        title: 'No se pudieron cargar los partos',
        error: error,
        onRetry: onRetry,
      ),
    ),
    data: (rows) {
      final pigsById = {
        for (final pig in pigs.valueOrNull ?? <Map<String, dynamic>>[])
          pig['id'] as String: pig,
      };
      final upcoming = rows.where(isPendingFarrowing).toList()
        ..sort(
          (a, b) => (a['fecha_estimada_parto'] as String).compareTo(
            b['fecha_estimada_parto'] as String,
          ),
        );
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ListTile(
                title: Text('Próximos partos (${upcoming.length})'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/partos/proximos'),
              ),
              if (upcoming.isEmpty)
                const ListTile(
                  leading: Icon(Icons.event_busy),
                  title: Text('No hay partos próximos registrados.'),
                )
              else
                ...upcoming.take(5).map((row) {
                  final pig = pigsById[row['cerda_id']];
                  final earTag = pig == null
                      ? 'Cerda'
                      : 'Arete ${pig['arete']}';
                  final due = DateTime.parse(
                    row['fecha_estimada_parto'] as String,
                  );
                  final observation = (row['observaciones'] as String?)?.trim();
                  return ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text(
                      '$earTag · ${DateFormat.yMMMd('es').format(due)}',
                    ),
                    subtitle: Text(
                      observation == null || observation.isEmpty
                          ? 'Parto estimado'
                          : observation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => context.go('/partos/proximos'),
                  );
                }),
            ],
          ),
        ),
      );
    },
  );

  String _metricValue<T>(AsyncValue<T> value, String Function(T) format) =>
      value.when(loading: () => '…', error: (_, _) => '!', data: format);
}
