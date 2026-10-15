import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(supabaseClientProvider)),
);

final foodsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(foodRepositoryProvider).watchFoods();
});

final feedRecordsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(foodRepositoryProvider).watchFeedRecords();
});

class FoodRepository {
  FoodRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> watchFoods() =>
      _client.from('alimentos').stream(primaryKey: ['id']).order('nombre');

  Stream<List<Map<String, dynamic>>> watchFeedRecords() {
    final since = DateTime.now().subtract(const Duration(days: 6));
    return _client
        .from('consumos')
        .stream(primaryKey: ['id'])
        .gte('fecha', _dateOnly(since))
        .order('fecha', ascending: false);
  }

  Future<void> createFood({
    required String nombre,
    required double existenciaKg,
    String? etapa,
    String? tipo,
    double costoPorKg = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Inicia sesión para guardar.');

    await _client.from('alimentos').insert({
      'user_id': user.id,
      'nombre': nombre.trim(),
      'tipo': tipo?.trim().isEmpty ?? true ? null : tipo!.trim(),
      'existencia_kg': existenciaKg,
      'etapa': etapa,
      'costo_por_kg': costoPorKg,
    });
  }

  Future<void> updateFood({
    required String foodId,
    required String nombre,
    required double existenciaKg,
    String? etapa,
    String? tipo,
    required double costoPorKg,
  }) async {
    await _client
        .from('alimentos')
        .update({
          'nombre': nombre.trim(),
          'tipo': tipo?.trim().isEmpty ?? true ? null : tipo!.trim(),
          'existencia_kg': existenciaKg,
          'etapa': etapa,
          'costo_por_kg': costoPorKg,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', foodId);
  }

  Future<void> deleteFood(String foodId) async {
    await _client.from('alimentos').delete().eq('id', foodId);
  }

  Future<void> recordConsumption({
    required String foodId,
    required double quantityKg,
    required DateTime date,
    String? penId,
    String? observations,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Inicia sesión para guardar.');

    await _client.from('consumos').insert({
      'user_id': user.id,
      'alimento_id': foodId,
      'cantidad_kg': quantityKg,
      'fecha': _dateOnly(date),
      'corral_id': penId,
      'observaciones': observations?.trim().isEmpty ?? true
          ? null
          : observations!.trim(),
    });
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
