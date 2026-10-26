import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/resilient_stream.dart';
import '../../../core/supabase/supabase_client.dart';

final penRepositoryProvider = Provider<PenRepository>(
  (ref) => PenRepository(ref.watch(supabaseClientProvider)),
);

final pensProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(penRepositoryProvider).watchPens();
});

class PenRepository {
  PenRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> watchPens() => resilientStream(
    client: _client,
    fetch: () => _client.from('corrales').select().order('nombre'),
    realtime: () =>
        _client.from('corrales').stream(primaryKey: ['id']).order('nombre'),
  );

  Future<void> createPen({
    required String nombre,
    required int capacidad,
    String etapa = 'desarrollo',
    String? ubicacion,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Inicia sesión para guardar.');

    await _client.from('corrales').insert({
      'user_id': user.id,
      'nombre': nombre.trim(),
      'capacidad': capacidad,
      'etapa': etapa,
      'ubicacion': ubicacion?.trim().isEmpty ?? true ? null : ubicacion!.trim(),
    });
  }

  Future<void> updatePenState({
    required String penId,
    required String state,
  }) async {
    const allowedStates = {'normal', 'mantenimiento', 'alerta'};
    if (!allowedStates.contains(state)) {
      throw ArgumentError.value(state, 'state', 'Estado de corral no válido.');
    }

    await _client
        .from('corrales')
        .update({
          'estado': state,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', penId);
  }

  Future<void> updatePen({
    required String penId,
    required String nombre,
    required int capacidad,
    required String etapa,
    String? ubicacion,
  }) async {
    await _client
        .from('corrales')
        .update({
          'nombre': nombre.trim(),
          'capacidad': capacidad,
          'etapa': etapa,
          'ubicacion': ubicacion?.trim().isEmpty ?? true
              ? null
              : ubicacion!.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', penId);
  }

  /// Los cerdos del corral quedan sin asignar (`on delete set null`).
  Future<void> deletePen(String penId) async {
    await _client.from('corrales').delete().eq('id', penId);
  }
}
