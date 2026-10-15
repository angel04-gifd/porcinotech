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
        .signUp(email: email, password: password, nombre: nombre),
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
        final message = error.message.trim();
        throw AuthOperationException(
          message.isEmpty
              ? 'No se pudo completar la operación de autenticación.'
              : message,
        );
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

class AuthOperationException implements Exception {
  const AuthOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
