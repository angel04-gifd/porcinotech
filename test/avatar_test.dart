import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/core/widgets/user_avatar.dart';

/// Iniciales del avatar cuando la cuenta no tiene foto de Google.
void main() {
  group('iniciales del avatar', () {
    test('usa las dos primeras letras del nombre', () {
      expect(userInitials(name: 'Angel Jovani Benitez'), 'AJ');
      expect(userInitials(name: 'angel jovani'), 'AJ');
    });

    test('con un solo nombre usa una letra', () {
      expect(userInitials(name: 'Angel'), 'A');
    });

    test('ignora espacios de sobra', () {
      expect(userInitials(name: '   Lola    Pérez  '), 'LP');
    });

    test('sin nombre usa la primera letra del correo', () {
      expect(userInitials(name: '', email: 'yubi@correo.com'), 'Y');
      expect(userInitials(name: null, email: 'ana@correo.com'), 'A');
    });

    test('sin nombre ni correo muestra un signo de interrogación', () {
      expect(userInitials(), '?');
      expect(userInitials(name: '  ', email: ' '), '?');
    });
  });
}
