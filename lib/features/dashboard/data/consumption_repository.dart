import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

final consumptionRepositoryProvider = Provider<ConsumptionRepository>(
  (ref) => ConsumptionRepository(ref.watch(supabaseClientProvider)),
);

final todayConsumptionProvider = StreamProvider<double>((ref) {
  return ref.watch(consumptionRepositoryProvider).watchTodayTotal();
});

class ConsumptionRepository {
  ConsumptionRepository(this._client);

  final SupabaseClient _client;

  Stream<double> watchTodayTotal() {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return _client
        .from('consumos')
        .stream(primaryKey: ['id'])
        .eq('fecha', today)
        .map(
          (rows) => rows.fold<double>(
            0,
            (total, row) =>
                total + ((row['cantidad_kg'] as num?)?.toDouble() ?? 0),
          ),
        );
  }
}
