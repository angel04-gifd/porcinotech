import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/supabase/resilient_stream.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../profile/data/avatar_rules.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);
final authStateProvider = StreamProvider<AuthState>((ref) {
  // Sin servidor configurado todavía no existe el cliente de Supabase.
  if (ref.watch(appConfigProvider) == null) return const Stream.empty();
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});
final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUserEmail;
});
/// Foto de la cuenta de Google (si inició sesión con Google); null con correo y contraseña.
final currentUserAvatarProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUserAvatarUrl;
});
final currentProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId = authState?.session?.user.id;
  if (userId == null) return Stream.value(null);
  final client = ref.watch(supabaseClientProvider);
  return resilientStream<Map<String, dynamic>?>(
    client: client,
    fetch: () =>
        client.from('perfiles').select().eq('user_id', userId).maybeSingle(),
    realtime: () => client
        .from('perfiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((profiles) => profiles.isEmpty ? null : profiles.first),
  );
});
/// Granjas a las que pertenece el usuario (id, nombre, rol, codigo_invitacion
/// —solo si es administrador— y activa). Vacío si la migración
/// 20261003_multi_granja.sql no está aplicada.
final misGranjasProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final profile = ref.watch(currentProfileProvider).valueOrNull;
      if (profile == null) return const [];
      final rows = await ref
          .watch(supabaseClientProvider)
          .rpc('mis_granjas') as List<dynamic>;
      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });

/// Granja activa del usuario, o null si todavía no tiene ninguna.
final currentFarmProvider = Provider<Map<String, dynamic>?>((ref) {
  final farms = ref.watch(misGranjasProvider).valueOrNull ?? const [];
  for (final farm in farms) {
    if (farm['activa'] == true) return farm;
  }
  return null;
});

/// El tipo de cuenta es fijo: administrador (crea sus propias granjas) u
/// operador (solo se une con código a granjas de cualquier administrador).
/// Hasta que la persona elige por primera vez, puede hacer cualquiera de las dos.
final tipoCuentaProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  return profile?['tipo_cuenta'] as String?;
});

/// ¿Esta cuenta es la del administrador autorizado? Solo ella puede crear
/// granjas; todas las demás entran como operadores. La regla real la hace la
/// base de datos (crear_granja); esto solo evita mostrar opciones que fallarían.
/// Si no se puede consultar, se asume que NO (la opción segura).
final adminAutorizadoProvider = FutureProvider.autoDispose<bool>((ref) async {
  ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentSession == null) return false;
  final result = await client.rpc('soy_admin_autorizado');
  return result == true;
});
final puedeCrearGranjaProvider = Provider<bool>((ref) {
  final autorizado = ref.watch(adminAutorizadoProvider).valueOrNull ?? false;
  return autorizado && ref.watch(tipoCuentaProvider) != 'operador';
});
final puedeUnirseGranjaProvider = Provider<bool>((ref) {
  final autorizado = ref.watch(adminAutorizadoProvider).valueOrNull ?? false;
  return !autorizado;
});

/// Texto del acceso para agregar otra granja según el tipo de cuenta.
String textoAgregarGranja(bool puedeCrear, bool puedeUnirse) {
  if (puedeCrear && puedeUnirse) return 'Crear otra granja o unirme con código';
  return puedeCrear ? 'Crear otra granja' : 'Unirme a otra granja con código';
}

/// Equipo de la granja activa (solo lo puede consultar el administrador).
final equipoGranjaProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final profile = ref.watch(currentProfileProvider).valueOrNull;
      if (profile == null || profile['rol'] != 'admin') return const [];
      final rows = await ref
          .watch(supabaseClientProvider)
          .rpc('equipo_granja') as List<dynamic>;
      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  /// URL de la foto que Google entrega al iniciar sesión (`avatar_url` o `picture`).
  String? get currentUserAvatarUrl {
    final data = _client.auth.currentUser?.userMetadata;
    final url = (data?['avatar_url'] ?? data?['picture']) as String?;
    return url == null || url.trim().isEmpty ? null : url.trim();
  }

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
      data: nombre != null && nombre.trim().isNotEmpty
          ? {'nombre': nombre.trim()}
          : null,
    );
    return response.session == null;
  }

  /// Dirección a la que Google devuelve a la app (debe estar en Supabase, en
  /// Authentication > URL Configuration > Redirect URLs, y en AndroidManifest).
  static const googleRedirectUrl = 'io.supabase.porcinotech://login-callback/';

  /// Abre el inicio de sesión de Google en el navegador. La sesión llega
  /// después, cuando Google regresa a la app por [googleRedirectUrl].
  /// Las cuentas nuevas siempre nacen como operador (lo hace la base de datos).
  Future<void> signInWithGoogle() async {
    final opened = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: googleRedirectUrl,
    );
    if (!opened) {
      throw const AuthException(
        'No se pudo abrir el inicio de sesión con Google.',
      );
    }
  }

  Future<void> crearGranja(String nombre) =>
      _client.rpc('crear_granja', params: {'p_nombre': nombre});

  Future<void> unirseAGranja(String codigo) =>
      _client.rpc('unirse_a_granja', params: {'p_codigo': codigo});

  Future<void> cambiarGranja(String id) =>
      _client.rpc('cambiar_granja', params: {'p_granja': id});

  Future<void> quitarOperador(String userId) =>
      _client.rpc('quitar_operador', params: {'p_user': userId});

  Future<void> guardarDatosPersonales({
    required String nombre,
    required String telefono,
    required String puesto,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('No hay una sesión activa.');
    await _client
        .from('perfiles')
        .update({
          'nombre': nombre.trim(),
          'telefono': telefono.trim(),
          'puesto': puesto.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  /// Sube la foto al bucket "avatars" (en la carpeta del usuario) y guarda su
  /// dirección en el perfil. Ver supabase/migrations/20261104_foto_perfil.sql.
  Future<String> subirFotoPerfil(
    Uint8List bytes, {
    required String extension,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('No hay una sesión activa.');
    final bucket = _client.storage.from('avatars');
    final path = avatarStoragePath(user.id, extension);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: avatarContentType(extension),
      ),
    );
    // La marca de tiempo evita que se siga viendo la foto anterior guardada en caché.
    final url =
        '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    await _client
        .from('perfiles')
        .update({
          'foto_url': url,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id);
    // Si antes tenía una foto en otro formato, se borra para no dejarla huérfana.
    final others = avatarStoragePaths(user.id)..remove(path);
    try {
      await bucket.remove(others);
    } catch (_) {
      // No es grave: solo queda un archivo sin usar.
    }
    return url;
  }

  /// Quita la foto subida (vuelve la de Google o las iniciales).
  Future<void> quitarFotoPerfil() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('No hay una sesión activa.');
    await _client
        .from('perfiles')
        .update({
          'foto_url': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', user.id);
    try {
      await _client.storage.from('avatars').remove(avatarStoragePaths(user.id));
    } catch (_) {
      // El perfil ya no la usa; si el archivo no se pudo borrar, no afecta.
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Borra la cuenta y sus datos (ver supabase/migrations/20261102_eliminar_cuenta.sql).
  Future<void> eliminarMiCuenta() async {
    await _client.rpc('eliminar_mi_cuenta');
    await _client.auth.signOut();
  }

  /// Envía al correo un código para restablecer la contraseña.
  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  /// Valida el código del correo y guarda la nueva contraseña.
  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email.trim(),
      token: code.trim(),
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
