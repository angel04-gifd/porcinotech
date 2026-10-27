import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  group('errores de la base de datos', () {
    test('un "no existe" se explica sin mostrar la excepción', () {
      final text = friendlyError(
        const PostgrestException(
          message: 'El cerdo solicitado no existe.',
          code: 'P0002',
          details: 'Internal Server Error',
        ),
      );
      expect(text, contains('El cerdo solicitado no existe.'));
      expect(text, contains('otra granja'));
      expect(text, isNot(contains('PostgrestException')));
      expect(text, isNot(contains('P0002')));
    });

    test('las reglas de negocio se muestran tal cual, en español', () {
      expect(
        friendlyError(
          const PostgrestException(
            message: 'Stock insuficiente. Disponible: 5 kg.',
            code: 'P0001',
          ),
        ),
        'Stock insuficiente. Disponible: 5 kg.',
      );
    });

    test('un error técnico desconocido no se muestra en crudo', () {
      final text = friendlyError(
        const PostgrestException(message: 'syntax error at or near "x"', code: '42601'),
      );
      expect(text, isNot(contains('syntax')));
      expect(text, contains('Inténtalo de nuevo'));
    });

    test('un permiso denegado por seguridad de filas se explica', () {
      expect(
        friendlyError(
          const PostgrestException(
            message: 'new row violates row-level security policy',
            code: '42501',
          ),
        ),
        contains('rol'),
      );
    });
  });
}
