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

  group('motivo cuando el cerdo no tiene corral', () {
    test('un cerdo sin corral debe elegir un motivo', () {
      expect(
        validateNoPenReasonChoice(null, needsReason: true),
        'Indica por qué no tiene corral',
      );
      expect(validateNoPenReasonChoice('Venta', needsReason: true), isNull);
    });

    test('con corral no se pide motivo', () {
      expect(validateNoPenReasonChoice(null, needsReason: false), isNull);
    });

    test('"Otro" exige escribir el motivo', () {
      expect(validateNoPenReasonText(''), 'Escribe el motivo');
      expect(validateNoPenReasonText(null), isNotNull);
      expect(validateNoPenReasonText('Regalado'), isNull);
      expect(validateNoPenReasonText('x' * 61), isNotNull);
    });

    test('el motivo se guarda solo si no hay corral', () {
      expect(
        noPenReasonToSave(corralId: null, opcion: 'Matadero', otro: ''),
        'Matadero',
      );
      expect(
        noPenReasonToSave(corralId: 'c1', opcion: 'Matadero', otro: ''),
        isNull,
      );
      expect(noPenReasonToSave(corralId: null, opcion: null, otro: 'x'), isNull);
    });

    test('"Otro" guarda el texto escrito', () {
      expect(
        noPenReasonToSave(
          corralId: null,
          opcion: otherNoPenReason,
          otro: ' Regalado ',
        ),
        'Regalado',
      );
      expect(
        noPenReasonToSave(corralId: null, opcion: otherNoPenReason, otro: ' '),
        isNull,
      );
    });

    test('un motivo guardado se reconoce en el menú', () {
      expect(noPenReasonSelectionFor('venta').opcion, 'Venta');
      expect(noPenReasonSelectionFor('Matadero').opcion, 'Matadero');
      final otro = noPenReasonSelectionFor('Regalado');
      expect(otro.opcion, otherNoPenReason);
      expect(otro.otro, 'Regalado');
      expect(noPenReasonSelectionFor(null).opcion, isNull);
    });

    test('el motivo sugiere el estado del cerdo', () {
      expect(estadoSugeridoPorMotivo('Venta'), 'vendido');
      expect(estadoSugeridoPorMotivo('Matadero'), 'baja');
      expect(estadoSugeridoPorMotivo('Fallecimiento'), 'fallecido');
      expect(estadoSugeridoPorMotivo('Cuarentena o enfermería'), isNull);
      expect(estadoSugeridoPorMotivo(null), isNull);
    });

    test('la lista incluye venta y matadero', () {
      expect(noPenReasons, containsAll(['Venta', 'Matadero', 'Fallecimiento']));
    });

    test('el texto del corral muestra el nombre, el motivo o que falta', () {
      expect(penLabelFor(penName: 'Corral 1', motivo: 'Venta'), 'Corral 1');
      expect(penLabelFor(motivo: 'Venta'), 'Sin corral (Venta)');
      expect(penLabelFor(), 'Sin corral · falta el motivo');
      expect(penLabelFor(motivo: '  '), 'Sin corral · falta el motivo');
    });
  });

  group('monta reciente (inseminación)', () {
    final hoy = DateTime(2026, 11, 4);
    List<Map<String, dynamic>> montas(String fecha, {String cerda = 's1'}) => [
      {'cerda_id': cerda, 'fecha_monta': fecha},
    ];

    test('una monta de hoy cuenta', () {
      expect(
        hasRecentMating(sowIds: ['s1'], farrowings: montas('2026-11-04'), hoy: hoy),
        isTrue,
      );
    });

    test('una monta dentro de la ventana de $mountingWindowDays días cuenta', () {
      expect(
        hasRecentMating(sowIds: ['s1'], farrowings: montas('2026-11-01'), hoy: hoy),
        isTrue,
      );
    });

    test('una monta más vieja que la ventana ya no cuenta', () {
      expect(
        hasRecentMating(sowIds: ['s1'], farrowings: montas('2026-10-31'), hoy: hoy),
        isFalse,
      );
    });

    test('una monta con fecha futura no cuenta', () {
      expect(
        hasRecentMating(sowIds: ['s1'], farrowings: montas('2026-11-05'), hoy: hoy),
        isFalse,
      );
    });

    test('la monta de otra cerda no cuenta', () {
      expect(
        hasRecentMating(
          sowIds: ['s1'],
          farrowings: montas('2026-11-04', cerda: 's2'),
          hoy: hoy,
        ),
        isFalse,
      );
    });

    test('sin registros o con fecha ilegible no hay monta', () {
      expect(hasRecentMating(sowIds: ['s1'], farrowings: const [], hoy: hoy), isFalse);
      expect(
        hasRecentMating(sowIds: ['s1'], farrowings: montas('no-es-fecha'), hoy: hoy),
        isFalse,
      );
    });
  });

  group('convivencia de sexos en el corral', () {
    SexMixProblem? revisar({
      required String sexo,
      String stage = 'desarrollo',
      List<String> residentes = const [],
      bool monta = false,
    }) => checkSexMix(
      sexo: sexo,
      stage: stage,
      penName: 'Corral 1',
      residentSexes: residentes,
      recentMating: monta,
    );

    test('un macho en un corral de Gestación se bloquea', () {
      final problema = revisar(sexo: 'macho', stage: 'gestacion');
      expect(problema, isNotNull);
      expect(problema!.blocks, isTrue);
      expect(problema.message, contains('estresa'));
    });

    test('un macho se bloquea en Gestación aunque haya monta', () {
      expect(
        revisar(sexo: 'macho', stage: 'gestacion', residentes: ['hembra'], monta: true)!
            .blocks,
        isTrue,
      );
    });

    test('una hembra en Gestación sin macho no tiene problema', () {
      expect(revisar(sexo: 'hembra', stage: 'gestacion', residentes: ['hembra']), isNull);
    });

    test('una hembra en Gestación con un macho dentro solo se avisa', () {
      final problema = revisar(
        sexo: 'hembra',
        stage: 'gestacion',
        residentes: ['macho'],
      );
      expect(problema, isNotNull);
      expect(problema!.blocks, isFalse);
    });

    test('macho con hembras y sin monta reciente: se avisa, no se bloquea', () {
      final problema = revisar(sexo: 'macho', residentes: ['hembra', 'hembra']);
      expect(problema, isNotNull);
      expect(problema!.blocks, isFalse);
      expect(problema.message, contains('se pelean'));
      expect(problema.message, contains('$mountingWindowDays'));
    });

    test('macho con hembras durante la monta no tiene problema', () {
      expect(revisar(sexo: 'macho', residentes: ['hembra'], monta: true), isNull);
    });

    test('hembra que llega a un corral con macho y sin monta: se avisa', () {
      expect(revisar(sexo: 'hembra', residentes: ['macho']), isNotNull);
    });

    test('hembra con macho durante la monta no tiene problema', () {
      expect(revisar(sexo: 'hembra', residentes: ['macho'], monta: true), isNull);
    });

    test('mismo sexo o corral vacío no tienen problema', () {
      expect(revisar(sexo: 'macho', residentes: ['macho']), isNull);
      expect(revisar(sexo: 'hembra', residentes: ['hembra']), isNull);
      expect(revisar(sexo: 'macho'), isNull);
    });
  });
}
