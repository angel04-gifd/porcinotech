import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Cada cuánto se consulta la base de datos mientras Realtime no responde.
const realtimeFallbackPollInterval = Duration(seconds: 5);

/// Cuántas consultas seguidas sin Realtime se esperan antes de intentar
/// suscribirse otra vez (con la sesión ya renovada).
const _ticksBeforeResubscribe = 6;

/// Mínimo entre dos renovaciones de sesión, para no repetirlas sin parar.
const _minRefreshGap = Duration(seconds: 20);

DateTime? _lastSessionRefresh;

/// Devuelve los datos con una consulta normal y los mantiene al día con
/// Realtime, pero **no depende** de Realtime para mostrarlos.
///
/// `.stream()` de Supabase solo usa el websocket de Realtime. Si ese websocket
/// no conecta (por ejemplo con el token de sesión vencido) la lista nunca
/// llega, aunque guardar sí funcione por la API normal. Aquí:
///
/// 1. Se carga primero con [fetch] (consulta normal). Si la sesión venció, se
///    renueva y se reintenta una vez.
/// 2. Se abre [realtime] para recibir cambios al instante.
/// 3. Mientras Realtime no esté sano, se vuelve a consultar con [fetch] cada
///    [pollInterval], se renueva la sesión y se reintenta la suscripción.
///
/// El error solo llega a la pantalla si todavía no hay ningún dato que
/// mostrar; si ya había datos se conservan y se sigue intentando.
Stream<T> resilientStream<T>({
  required SupabaseClient client,
  required Future<T> Function() fetch,
  required Stream<T> Function() realtime,
  Duration pollInterval = realtimeFallbackPollInterval,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timer;
  var closed = false;
  var hasData = false;
  var realtimeHealthy = false;
  var loading = false;
  var unhealthyTicks = 0;

  void emit(T value) {
    if (closed) return;
    hasData = true;
    controller.add(value);
  }

  void emitError(Object error, StackTrace stackTrace) {
    if (closed || hasData) return;
    controller.addError(error, stackTrace);
  }

  Future<void> load() async {
    if (closed || loading) return;
    loading = true;
    try {
      emit(await _fetchRenewingSession(client, fetch));
    } catch (error, stackTrace) {
      emitError(error, stackTrace);
    } finally {
      loading = false;
    }
  }

  void subscribe() {
    subscription?.cancel();
    realtimeHealthy = false;
    subscription = realtime().listen(
      (value) {
        realtimeHealthy = true;
        emit(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        realtimeHealthy = false;
        unawaited(_renewSession(client));
        emitError(error, stackTrace);
      },
    );
  }

  controller = StreamController<T>(
    onListen: () {
      unawaited(load());
      subscribe();
      timer = Timer.periodic(pollInterval, (_) {
        if (realtimeHealthy) {
          unhealthyTicks = 0;
          return;
        }
        unawaited(load());
        unhealthyTicks++;
        if (unhealthyTicks >= _ticksBeforeResubscribe) {
          unhealthyTicks = 0;
          unawaited(_renewSession(client));
          subscribe();
        }
      });
    },
    onCancel: () {
      closed = true;
      timer?.cancel();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}

/// ¿El error se debe a que la sesión venció o ya no es válida?
bool isSessionError(Object error) {
  if (_isNetworkError(error)) return false;
  if (error is AuthException) return true;
  final text = error.toString().toLowerCase();
  return text.contains('jwt') ||
      text.contains('token has expired') ||
      text.contains('refresh_token') ||
      text.contains('pgrst301');
}

/// ¿El error se debe a que no hay conexión con el servidor?
bool _isNetworkError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('timeoutexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection closed') ||
      text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('retryablefetch') ||
      text.contains('timedout');
}

/// Hace la consulta y, si falla por sesión vencida, renueva la sesión y la
/// repite una sola vez.
Future<T> _fetchRenewingSession<T>(
  SupabaseClient client,
  Future<T> Function() fetch,
) async {
  try {
    return await fetch();
  } catch (error) {
    if (!isSessionError(error) || client.auth.currentSession == null) {
      rethrow;
    }
    await client.auth.refreshSession();
    return fetch();
  }
}

/// Renueva el token de sesión (supabase_flutter lo reparte a Realtime).
Future<void> _renewSession(SupabaseClient client) async {
  if (client.auth.currentSession == null) return;
  final now = DateTime.now();
  final last = _lastSessionRefresh;
  if (last != null && now.difference(last) < _minRefreshGap) return;
  _lastSessionRefresh = now;
  try {
    await client.auth.refreshSession();
  } catch (_) {
    // Sin internet o sesión inválida: el siguiente intento lo vuelve a probar.
  }
}
