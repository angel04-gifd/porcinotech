import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/core/supabase/resilient_stream.dart';
import 'package:porcinotech/core/widgets/error_view.dart';

void main() {
  // Mensajes reales que mostraba la app cuando Realtime fallaba.
  final timedOut = Exception(
    'RealtimeSubscribeException(status: timedOut, details: null)',
  );
  final expiredToken = Exception(
    'RealtimeSubscribeException(status: channelError, details: Exception: '
    '"InvalidJWTToken: Token has expired 295109 seconds ago")',
  );

  test('el timeout de Realtime se explica como falta de conexión', () {
    expect(isSessionError(timedOut), isFalse);
    expect(friendlyError(timedOut), contains('conexión'));
  });

  test('el token vencido se explica como sesión vencida', () {
    expect(isSessionError(expiredToken), isTrue);
    expect(friendlyError(expiredToken), contains('sesión venció'));
  });

  test('un error desconocido no muestra la excepción cruda', () {
    final message = friendlyError(StateError('algo raro'));
    expect(message, isNot(contains('StateError')));
    expect(message, contains('inesperado'));
  });
}
