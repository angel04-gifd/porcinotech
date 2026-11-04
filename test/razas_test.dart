import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/features/cerdos/data/pig_rules.dart';

/// Raza como menú desplegable: evita "Durock" / "duroc" escritos distinto.
void main() {
  group('raza guardada → opción del menú', () {
    test('una raza de la lista se reconoce sin importar mayúsculas', () {
      expect(breedSelectionFor('duroc').opcion, 'Duroc');
      expect(breedSelectionFor('  YORKSHIRE ').opcion, 'Yorkshire');
    });

    test('se reconoce con o sin acento', () {
      expect(breedSelectionFor('Piétrain').opcion, 'Pietrain');
    });

    test('una raza fuera de la lista queda como "Otra" con su texto', () {
      final seleccion = breedSelectionFor('Durock');
      expect(seleccion.opcion, otherBreed);
      expect(seleccion.otra, 'Durock');
    });

    test('vacía o nula no elige nada', () {
      expect(breedSelectionFor(null).opcion, isNull);
      expect(breedSelectionFor('   ').opcion, isNull);
    });
  });

  group('opción del menú → raza que se guarda', () {
    test('una raza de la lista se guarda tal cual', () {
      expect(breedToSave(opcion: 'Landrace', otra: ''), 'Landrace');
    });

    test('sin elegir no se guarda raza', () {
      expect(breedToSave(opcion: null, otra: 'ignorado'), isNull);
    });

    test('"Otra" guarda el texto escrito', () {
      expect(breedToSave(opcion: otherBreed, otra: ' Cuino '), 'Cuino');
    });

    test('"Otra" con una raza de la lista la normaliza', () {
      expect(breedToSave(opcion: otherBreed, otra: 'duroc'), 'Duroc');
    });

    test('"Otra" vacía no guarda nada', () {
      expect(breedToSave(opcion: otherBreed, otra: '  '), isNull);
    });
  });

  group('raza escrita en "Otra"', () {
    test('es obligatoria', () {
      expect(validateOtherBreed(''), isNotNull);
      expect(validateOtherBreed(null), isNotNull);
    });

    test('acepta un texto normal y rechaza uno larguísimo', () {
      expect(validateOtherBreed('Cuino'), isNull);
      expect(validateOtherBreed('x' * 41), isNotNull);
    });
  });

  test('la lista incluye las razas pedidas', () {
    expect(
      pigBreeds,
      containsAll(['Duroc', 'Yorkshire', 'Landrace', 'Hampshire', 'Pietrain', 'Criollo']),
    );
  });
}
