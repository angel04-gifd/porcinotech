import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/features/cerdos/data/pig_rules.dart';

/// Validaciones del formulario de cerdos: nombre, corral y convivencia.
void main() {
  group('nombre del cerdo', () {
    test('es opcional: vacío o nulo es válido', () {
      expect(validatePigName(''), isNull);
      expect(validatePigName(null), isNull);
      expect(validatePigName('   '), isNull);
    });

    test('un nombre normal es válido', () {
      expect(validatePigName('Don Pancho'), isNull);
      expect(validatePigName('Lola 2'), isNull);
    });

    test('no puede ser solo números', () {
      expect(validatePigName('0055'), contains('solo números'));
      expect(validatePigName(' 55 '), contains('solo números'));
    });

    test('no puede ser igual al arete de otro cerdo', () {
      expect(
        validatePigName('A-12', aretes: ['0001', 'a-12']),
        contains('arete de otro cerdo'),
      );
    });

    test('un nombre distinto a los aretes es válido', () {
      expect(validatePigName('Rosita', aretes: ['0001', '0002']), isNull);
    });
  });

  group('corral al registrar un cerdo', () {
    test('un cerdo nuevo exige elegir corral', () {
      expect(validatePenChoice(null, isNewPig: true), 'Elige un corral');
    });

    test('un cerdo nuevo con corral es válido', () {
      expect(validatePenChoice('corral-1', isNewPig: true), isNull);
    });

    test('al editar un cerdo viejo sin corral no se bloquea', () {
      expect(validatePenChoice(null, isNewPig: false), isNull);
    });
  });
}
