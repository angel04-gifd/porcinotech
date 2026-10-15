import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);
final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUserEmail;
});
final currentProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId = authState?.session?.user.id;
  if (userId == null) return Stream.value(null);
  return ref
      .watch(supabaseClientProvider)
      .from('perfiles')
      .stream(primaryKey: ['user_id'])
      .eq('user_id', userId)
      .map((profiles) => profiles.isEmpty ? null : profiles.first);
});
final currentUserRoleProvider = Provider<AsyncValue<String?>>((ref) {
  return ref.watch(currentProfileProvider).whenData((profile) {
    if (profile == null) return null;
    final role = profile['rol'];
    if (role != 'admin' && role != 'operador') {
      throw StateError('El perfil tiene un rol no válido.');
    }
    return role as String;
  });
});

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;
  String? get currentUserEmail => _client.auth.currentUser?.email;

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.session == null) {
      throw const AuthException('No fue posible iniciar sesión.');
    }
    try {
      return await currentUserRole();
    } catch (_) {
      await _client.auth.signOut();
      rethrow;
    }
  }

  Future<String> currentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No hay una sesión activa.');
    }
    final profile = await _client
        .from('perfiles')
        .select('rol')
        .eq('user_id', user.id)
        .maybeSingle();
    final role = profile?['rol'];
    if (role != 'admin' && role != 'operador') {
      throw const AuthException(
        'El perfil no existe o tiene un rol no válido. Contacta al administrador.',
      );
    }
    return role as String;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? nombre,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: nombre == null || nombre.isEmpty ? null : {'nombre': nombre},
    );
    return response.session == null;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
}
