import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

const gestationDays = 114; // 3 meses, 3 semanas y 3 días.

final farrowingRepositoryProvider = Provider<FarrowingRepository>(
  (ref) => FarrowingRepository(ref.watch(supabaseClientProvider)),
);

final farrowingsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(farrowingRepositoryProvider).watchFarrowings();
});

/// Suma días por calendario, no por horas, para no desfasarse con el horario de verano.
DateTime dueDateFor(DateTime matingDate) =>
    DateTime(matingDate.year, matingDate.month, matingDate.day + gestationDays);

/// Gestación mínima aceptada para registrar un parto real (validada también
/// en la base de datos).
const minGestationDays = 100;

/// Primer día en que puede registrarse el parto real de una monta.
DateTime earliestBirthDate(DateTime matingDate) => DateTime(
  matingDate.year,
  matingDate.month,
  matingDate.day + minGestationDays,
);

/// Gestación en curso: sin parto real registrado y no marcada como fallida.
bool isPendingFarrowing(Map<String, dynamic> row) =>
    row['fecha_parto'] == null && row['fallida'] != true;

/// Gestación en curso (sin parto real registrado) más reciente de una cerda.
Map<String, dynamic>? pendingFarrowingFor(
  String sowId,
  List<Map<String, dynamic>> farrowings,
) {
  final pending =
      farrowings
          .where((row) => row['cerda_id'] == sowId && isPendingFarrowing(row))
          .toList()
        ..sort(
          (a, b) => (b['fecha_monta'] as String).compareTo(
            a['fecha_monta'] as String,
          ),
        );
  return pending.isEmpty ? null : pending.first;
}

class FarrowingRepository {
  FarrowingRepository(this._client);

  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> watchFarrowings() => _client
      .from('partos')
      .stream(primaryKey: ['id'])
      .order('fecha_estimada_parto');

  Future<void> createFarrowing({
    required String sowId,
    required DateTime matingDate,
    String? observations,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Inicia sesión para guardar.');

    await _client.from('partos').insert({
      'user_id': user.id,
      'cerda_id': sowId,
      'fecha_monta': _dateOnly(matingDate),
      'fecha_estimada_parto': _dateOnly(dueDateFor(matingDate)),
      'observaciones': observations?.trim().isEmpty ?? true
          ? null
          : observations!.trim(),
    });
  }

  Future<void> registerBirth({
    required String farrowingId,
    required DateTime birthDate,
    required int bornPiglets,
    required int livePiglets,
  }) async {
    await _client
        .from('partos')
        .update({
          'fecha_parto': _dateOnly(birthDate),
          'lechones_nacidos': bornPiglets,
          'lechones_vivos': livePiglets,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', farrowingId);
  }

  /// Cierra una gestación que no llegó a parto (aborto o monta sin preñez)
  /// para que la cerda vuelva a estar disponible.
  Future<void> markFailed(String farrowingId) async {
    await _client
        .from('partos')
        .update({
          'fallida': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', farrowingId);
  }

  Future<void> deleteFarrowing(String farrowingId) async {
    await _client.from('partos').delete().eq('id', farrowingId);
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
