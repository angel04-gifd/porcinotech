import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cerdos/data/pig_repository.dart';
import '../../corrales/data/pen_repository.dart';
import 'production_stage_repository.dart';

/// Ración diaria de un corral: cerdos activos × ración de la etapa del corral.
class PenFeedNeed {
  const PenFeedNeed({
    required this.penId,
    required this.penName,
    required this.stage,
    required this.stageName,
    required this.pigCount,
    required this.rationPerPig,
  });

  final String penId;
  final String penName;
  final String stage;
  final String stageName;
  final int pigCount;
  final double rationPerPig;

  double get dailyKg => pigCount * rationPerPig;
}

class FeedPlan {
  const FeedPlan({required this.pens, required this.unassignedPigs});

  final List<PenFeedNeed> pens;

  /// Cerdos activos sin corral: no tienen etapa, así que no suman ración.
  final int unassignedPigs;

  List<PenFeedNeed> pensForStage(String? stage) =>
      stage == null ? pens : pens.where((pen) => pen.stage == stage).toList();

  double dailyKgForStage(String? stage) =>
      pensForStage(stage).fold(0, (sum, pen) => sum + pen.dailyKg);

  double get totalDailyKg => dailyKgForStage(null);
}

bool isActivePig(Map<String, dynamic> pig) => pig['estado'] == 'activo';

final feedPlanProvider = Provider<AsyncValue<FeedPlan>>((ref) {
  final pens = ref.watch(pensProvider);
  final pigs = ref.watch(pigsProvider);
  final stages = ref.watch(productionStagesProvider);

  for (final value in [pens, pigs, stages]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace!);
  }
  if (!pens.hasValue || !pigs.hasValue || !stages.hasValue) {
    return const AsyncLoading();
  }

  final stagesByKey = {
    for (final stage in stages.requireValue) stage['etapa'] as String: stage,
  };
  final activePigs = pigs.requireValue.where(isActivePig).toList();
  final penIds = {for (final pen in pens.requireValue) pen['id']};

  return AsyncData(
    FeedPlan(
      pens: [
        for (final pen in pens.requireValue)
          () {
            final stageKey = pen['etapa'] as String? ?? 'desarrollo';
            final stage = stagesByKey[stageKey];
            return PenFeedNeed(
              penId: pen['id'] as String,
              penName: pen['nombre'] as String,
              stage: stageKey,
              stageName: stage?['nombre'] as String? ?? stageKey,
              pigCount: activePigs
                  .where((pig) => pig['corral_id'] == pen['id'])
                  .length,
              rationPerPig:
                  (stage?['racion_sugerida_kg_por_cerdo_dia'] as num?)
                      ?.toDouble() ??
                  0,
            );
          }(),
      ],
      unassignedPigs: activePigs
          .where((pig) => !penIds.contains(pig['corral_id']))
          .length,
    ),
  );
});
