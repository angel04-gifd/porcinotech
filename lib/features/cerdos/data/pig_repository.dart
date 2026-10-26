import 'dart:math' show max;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/resilient_stream.dart';
import '../../../core/supabase/supabase_client.dart';

final pigRepositoryProvider = Provider<PigRepository>(
  (ref) => PigRepository(ref.watch(supabaseClientProvider)),
);

final pigsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(pigRepositoryProvider).watchPigs();
});

class PigRepository {
  PigRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> watchPigs() => resilientStream(
    client: _client,
    fetch: () => _client
        .from('cerdos')
        .select()
        .order('created_at', ascending: false),
    realtime: () => _client
        .from('cerdos')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false),
  );

  /// Siguiente arete consecutivo de 4 dígitos ("0001", "0002", …).
  static String nextEarTag(Iterable<String> existing) {
    final highest = existing
        .map((arete) => int.tryParse(arete) ?? 0)
        .fold<int>(0, max);
    return (highest + 1).toString().padLeft(4, '0');
  }

  Future<String> _nextEarTagFromDb() async {
    final rows = await _client.from('cerdos').select('arete');
    return nextEarTag(rows.map((row) => row['arete'] as String));
  }

  /// Crea el cerdo con el siguiente arete libre y lo devuelve.
  Future<String> createPig({
    required String sexo,
    String? nombre,
    String? raza,
    double? peso,
    String? corralId,
    DateTime? fechaNacimiento,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Inicia sesión para guardar.');

    // Reintenta si otro usuario tomó el mismo número al mismo tiempo.
    for (var attempt = 0; ; attempt++) {
      final arete = await _nextEarTagFromDb();
      try {
        await _client.from('cerdos').insert({
          'user_id': user.id,
          'arete': arete,
          'nombre': nombre?.trim().isEmpty ?? true ? null : nombre!.trim(),
          'raza': raza?.trim().isEmpty ?? true ? null : raza!.trim(),
          'peso': peso,
          'sexo': sexo,
          'corral_id': corralId,
          'fecha_nacimiento': fechaNacimiento == null
              ? null
              : _dateOnly(fechaNacimiento),
        });
        return arete;
      } on PostgrestException catch (error) {
        if (error.code != '23505' || attempt >= 2) rethrow;
      }
    }
  }

  Future<void> updatePig({
    required String pigId,
    required String sexo,
    required String estado,
    String? nombre,
    String? raza,
    double? peso,
    String? corralId,
    DateTime? fechaNacimiento,
  }) async {
    await _client
        .from('cerdos')
        .update({
          'nombre': nombre?.trim().isEmpty ?? true ? null : nombre!.trim(),
          'raza': raza?.trim().isEmpty ?? true ? null : raza!.trim(),
          'peso': peso,
          'sexo': sexo,
          'estado': estado,
          'corral_id': corralId,
          'fecha_nacimiento': fechaNacimiento == null
              ? null
              : _dateOnly(fechaNacimiento),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', pigId);
  }

  Future<String> deleteOrArchivePig(String pigId) async =>
      await _client.rpc(
            'eliminar_o_archivar_cerdo',
            params: {'p_cerdo_id': pigId},
          )
          as String;

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
