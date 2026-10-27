import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> signIn({required String email, required String password}) =>
      _run<String>(
        () => ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password),
      );

  Future<void> signInWithGoogle() async {
    await _run<void>(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<void> recoverPassword({required String email}) async {
    await _run<void>(
      () => ref.read(authRepositoryProvider).sendPasswordReset(email),
    );
  }

  Future<void> signOut() async {
    await _run<void>(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<bool?> signUp({
    required String email,
    required String password,
    String? nombre,
  }) => _run<bool>(
    () => ref
        .read(authRepositoryProvider)
        .signUp(
          email: email,
          password: password,
          nombre: nombre,
        ),
  );

  Future<T?> _run<T>(Future<T> Function() operation) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard<T>(() async {
      try {
        // Sin límite, una red que no llega al servidor deja el login cargando para siempre.
        return await operation().timeout(const Duration(seconds: 20));
      } on TimeoutException {
        throw const AuthOperationException(
          'El servidor no responde. Revisa tu conexión a internet o cambia de red (Wi-Fi / datos móviles).',
        );
      } on AuthRetryableFetchException {
        throw const AuthOperationException(
          'Sin conexión con el servidor. Revisa tu internet e inténtalo de nuevo.',
        );
      } on AuthException catch (error) {
        throw AuthOperationException(traducirErrorAuth(error.message));
      } catch (_) {
        throw const AuthOperationException(
          'Ocurrió un error al conectar con el servicio. Inténtalo de nuevo.',
        );
      }
    });

    state = result.when<AsyncValue<void>>(
      loading: () => const AsyncLoading<void>(),
      data: (_) => const AsyncData<void>(null),
      error: (error, stackTrace) => AsyncError<void>(error, stackTrace),
    );
    return result.valueOrNull;
  }
}

/// Los mensajes de Supabase Auth vienen en inglés; aquí se pasan a español.
/// Un mensaje que no se reconoce y ya está en español se deja tal cual.
String traducirErrorAuth(String original) {
  final message = original.trim();
  if (message.isEmpty) {
    return 'No se pudo completar la operación de autenticación.';
  }
  final text = message.toLowerCase();
  if (text.contains('invalid login credentials')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (text.contains('email not confirmed')) {
    return 'Aún no confirmas tu correo. Revisa tu bandeja de entrada.';
  }
  if (text.contains('user already registered') ||
      text.contains('already been registered')) {
    return 'Ese correo ya tiene una cuenta. Inicia sesión.';
  }
  if (text.contains('password should be at least')) {
    return 'La contraseña es demasiado corta.';
  }
  if (text.contains('same password') || text.contains('different from the old')) {
    return 'La nueva contraseña debe ser distinta de la anterior.';
  }
  if (text.contains('rate limit') || text.contains('too many requests')) {
    return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
  }
  if (text.contains('token has expired') ||
      text.contains('otp_expired') ||
      text.contains('expired or is invalid')) {
    return 'El código venció o no es válido. Pide uno nuevo.';
  }
  if (text.contains('invalid email') || text.contains('unable to validate email')) {
    return 'El correo no es válido.';
  }
  if (text.contains('signup') && text.contains('disabled')) {
    return 'El registro está desactivado por ahora.';
  }
  return message;
}

class AuthOperationException implements Exception {
  const AuthOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
