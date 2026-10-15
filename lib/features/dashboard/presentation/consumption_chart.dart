import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Colores fijos por etapa (paleta categórica validada para daltonismo).
/// Cada etapa conserva su color aunque no tenga consumo ese día.
const stageColors = {
  'pre_inicio': Color(0xff2a78d6),
  'inicio': Color(0xffeb6834),
  'desarrollo': Color(0xff1baf7a),
  'engorda': Color(0xffeda100),
  'gestacion': Color(0xffe87ba4),
  'lactancia': Color(0xff008300),
  generalStage: Color(0xff4a3aa7),
};
const generalStage = 'general';

/// Consumo de los últimos 7 días apilado por etapa productiva del alimento.
class ConsumptionByStageChart extends StatelessWidget {
  const ConsumptionByStageChart({
    super.key,
    required this.records,
    required this.foods,
    required this.stageNames,
  });

  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> foods;

  /// Etapas en orden productivo: clave → nombre visible.
  final Map<String, String> stageNames;

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodStage = {
      for (final food in foods)
        food['id'] as String: food['etapa'] as String? ?? generalStage,
    };
    final today = DateUtils.dateOnly(DateTime.now());
    final days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - 6 + index),
    );
    // totals[día][etapa] = kg
    final totals = [
      for (final day in days)
        () {
          final key = _dateKey(day);
          final byStage = <String, double>{};
          for (final row in records.where((row) => row['fecha'] == key)) {
            final stage = foodStage[row['alimento_id']] ?? generalStage;
            byStage[stage] =
                (byStage[stage] ?? 0) +
                ((row['cantidad_kg'] as num?)?.toDouble() ?? 0);
          }
          return byStage;
        }(),
    ];
    final order = [...stageNames.keys, generalStage];
    final names = {...stageNames, generalStage: 'General'};
    final usedStages = order
        .where((stage) => totals.any((day) => (day[stage] ?? 0) > 0))
        .toList();
    final dayTotals = [
      for (final day in totals) day.values.fold<double>(0, (a, b) => a + b),
    ];
    final maximum = dayTotals.fold<double>(0, math.max);
    final interval = _niceInterval(maximum);
    final maxY = maximum <= 0 ? 4.0 : (maximum / interval).ceil() * interval;
    final surface = theme.cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItem: (group, _, _, _) {
                    final day = totals[group.x];
                    final lines = [
                      for (final stage in order)
                        if ((day[stage] ?? 0) > 0)
                          '${names[stage]}: ${day[stage]!.toStringAsFixed(1)} kg',
                    ];
                    return BarTooltipItem(
                      '${DateFormat.MMMEd('es').format(days[group.x])}\n'
                      'Total ${dayTotals[group.x].toStringAsFixed(1)} kg'
                      '${lines.isEmpty ? '' : '\n${lines.join('\n')}'}',
                      TextStyle(
                        color: theme.colorScheme.onInverseSurface,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: interval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.toStringAsFixed(0),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        DateFormat.E('es').format(days[value.toInt()]),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var index = 0; index < days.length; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dayTotals[index],
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        rodStackItems: () {
                          var from = 0.0;
                          return [
                            for (final stage in order)
                              if ((totals[index][stage] ?? 0) > 0)
                                () {
                                  final to = from + totals[index][stage]!;
                                  final item = BarChartRodStackItem(
                                    from,
                                    to,
                                    stageColors[stage]!,
                                    borderSide: BorderSide(
                                      color: surface,
                                      width: 1,
                                    ),
                                  );
                                  from = to;
                                  return item;
                                }(),
                          ];
                        }(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (usedStages.isEmpty)
          Text(
            'Sin consumos registrados en estos días.',
            style: theme.textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final stage in usedStages)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: stageColors[stage],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${names[stage]!.split(' (').first} '
                      '${totals.fold<double>(0, (sum, day) => sum + (day[stage] ?? 0)).toStringAsFixed(0)} kg',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  /// Intervalo "redondo" (1, 2, 5 × 10ⁿ) para ~4 líneas de cuadrícula.
  double _niceInterval(double maximum) {
    if (maximum <= 0) return 1;
    final raw = maximum / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
    for (final step in [1, 2, 5, 10]) {
      if (raw <= step * magnitude) return (step * magnitude).toDouble();
    }
    return (10 * magnitude).toDouble();
  }
}
