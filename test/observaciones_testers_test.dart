import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/core/widgets/number_formatters.dart';
import 'package:porcinotech/features/auth/presentation/auth_controller.dart';
import 'package:porcinotech/features/cerdos/data/pig_rules.dart';

void main() {
  group('peso según la edad (observación 7 de Julio10Mon)', () {
    final hoy = DateTime(2026, 10, 22);

    test('un cerdo de 6 días con 77 kg recibe aviso', () {
      final aviso = pesoIncoherenteConEdad(
        pesoKg: 77,
        nacimiento: DateTime(2026, 10, 16),
        hoy: hoy,
      );
      expect(aviso, isNotNull);
      expect(aviso, contains('6 días'));
    });

    test('un lechón de 6 días con 2 kg es normal', () {
      expect(
        pesoIncoherenteConEdad(
          pesoKg: 2,
          nacimiento: DateTime(2026, 10, 16),
          hoy: hoy,
        ),
        isNull,
      );
    });

    test('un adulto de 2 años con 250 kg es normal', () {
      expect(
        pesoIncoherenteConEdad(
          pesoKg: 250,
          nacimiento: DateTime(2024, 10, 22),
          hoy: hoy,
        ),
        isNull,
      );
    });

    test('sin peso o sin fecha de nacimiento no avisa', () {
      expect(
        pesoIncoherenteConEdad(pesoKg: null, nacimiento: DateTime(2026), hoy: hoy),
        isNull,
      );
      expect(
        pesoIncoherenteConEdad(pesoKg: 80, nacimiento: null, hoy: hoy),
        isNull,
      );
    });

    test('el límite nunca pasa del peso máximo permitido', () {
      expect(maxPlausibleWeightKg(5000), maxPigWeightKg.toDouble());
    });
  });

  group('ceros a la izquierda (observación 10 de Julio10Mon)', () {
    test('quita los ceros sobrantes', () {
      expect(sinCerosIzquierda('010'), '10');
      expect(sinCerosIzquierda('007.5'), '7.5');
      expect(sinCerosIzquierda('00'), '0');
    });

    test('respeta 0, 0.5 y 0,25', () {
      expect(sinCerosIzquierda('0'), '0');
      expect(sinCerosIzquierda('0.5'), '0.5');
      expect(sinCerosIzquierda('0,25'), '0,25');
      expect(sinCerosIzquierda(''), '');
    });

    test('el formateador deja el cursor al final al escribir', () {
      const formatter = NoLeadingZerosFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '0',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(
          text: '01',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, '1');
      expect(result.selection.baseOffset, 1);
    });
  });

  group('errores de autenticación en español (observación 6)', () {
    test('traduce las credenciales inválidas', () {
      expect(
        traducirErrorAuth('Invalid login credentials'),
        'Correo o contraseña incorrectos.',
      );
    });

    test('traduce otros mensajes comunes', () {
      expect(traducirErrorAuth('Email not confirmed'), contains('correo'));
      expect(traducirErrorAuth('User already registered'), contains('cuenta'));
      expect(
        traducirErrorAuth('Password should be at least 6 characters.'),
        contains('contraseña'),
      );
    });

    test('un mensaje vacío o ya en español no se pierde', () {
      expect(traducirErrorAuth('  '), contains('autenticación'));
      expect(traducirErrorAuth('Solo el administrador autorizado.'),
          'Solo el administrador autorizado.');
    });
  });
}
