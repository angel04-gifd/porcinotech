import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

final productionStageRepositoryProvider = Provider<ProductionStageRepository>(
  (ref) => ProductionStageRepository(ref.watch(supabaseClientProvider)),
);

final productionStagesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(productionStageRepositoryProvider).getStages();
});

class ProductionStageRepository {
  ProductionStageRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>>
  getStages() async => List<Map<String, dynamic>>.from(
    await _client
        .from('etapas_productivas')
        .select(
          'etapa,nombre,orden,peso_min_kg,peso_max_kg,racion_sugerida_kg_por_cerdo_dia',
        )
        .order('orden'),
  );
}
