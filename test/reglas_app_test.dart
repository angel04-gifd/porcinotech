import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/features/alimentos/data/feed_plan.dart';
import 'package:porcinotech/features/cerdos/data/pig_repository.dart';
import 'package:porcinotech/features/cerdos/data/pig_rules.dart';
import 'package:porcinotech/features/partos/data/farrowing_repository.dart';

/// Lo que la app DEBE y NO DEBE hacer (reglas de negocio).
void main() {
  group('peso de un cerdo', () {
    test('acepta vacío, punto y coma decimal', () {
      expect(validatePigWeight(''), isNull);
      expect(validatePigWeight(null), isNull);
      expect(validatePigWeight('12,5'), isNull);
      expect(validatePigWeight('12.5'), isNull);
      expect(validatePigWeight('400'), isNull);
    });

    test('rechaza texto, cero, negativos y más de 400 kg', () {
      expect(validatePigWeight('abc'), isNotNull);
      expect(validatePigWeight('0'), contains('mayor que 0'));
      expect(validatePigWeight('-1'), isNotNull);
      expect(validatePigWeight('401'), contains('400'));
    });
  });

  group('lechones: peso contra su edad (pide confirmación al pasarse)', () {
    final hoy = DateTime(2026, 11, 3);
    final nacidoHace18 = DateTime(2026, 10, 16);

    test('dentro del rango no pregunta nada', () {
      for (final peso in [4.0, 6.0, 7.5]) {
        expect(
          pesoIncoherenteConEdad(pesoKg: peso, nacimiento: nacidoHace18, hoy: hoy),
          isNull,
          reason: '$peso kg a los 18 días es normal',
        );
      }
    });

    test('por encima del rango pregunta e indica el rango', () {
      for (final peso in [8.5, 12.0, 25.0, 77.0]) {
        final aviso = pesoIncoherenteConEdad(
          pesoKg: peso,
          nacimiento: nacidoHace18,
          hoy: hoy,
        );
        expect(aviso, isNotNull, reason: '$peso kg a los 18 días es mucho');
        expect(aviso, contains('18 días'));
        expect(aviso, contains('kg'));
      }
    });

    test('un recién nacido de 1.5 kg es normal y uno de 10 kg no', () {
      expect(pesoIncoherenteConEdad(pesoKg: 1.5, nacimiento: hoy, hoy: hoy), isNull);
      expect(pesoIncoherenteConEdad(pesoKg: 10, nacimiento: hoy, hoy: hoy), isNotNull);
    });

    test('un cerdo de engorda de 100 kg a los 185 días es normal', () {
      expect(
        pesoIncoherenteConEdad(
          pesoKg: 100,
          nacimiento: DateTime(2026, 5, 1),
          hoy: hoy,
        ),
        isNull,
      );
    });
  });

  group('corrales', () {
    test('admite otro cerdo solo si no está lleno', () {
      expect(penHasRoom(capacity: 5, activeResidents: 4), isTrue);
      expect(penHasRoom(capacity: 5, activeResidents: 5), isFalse);
      expect(penHasRoom(capacity: 5, activeResidents: 6), isFalse);
    });
  });

  group('aretes', () {
    test('el siguiente es consecutivo de 4 dígitos', () {
      expect(PigRepository.nextEarTag([]), '0001');
      expect(PigRepository.nextEarTag(['0001', '0002']), '0003');
      expect(PigRepository.nextEarTag(['0009']), '0010');
    });

    test('ignora aretes que no son número', () {
      expect(PigRepository.nextEarTag(['DM-D01', '0005']), '0006');
    });
  });

  group('gestación y partos', () {
    test('el parto estimado es la monta más 114 días', () {
      expect(dueDateFor(DateTime(2026, 1, 1)), DateTime(2026, 4, 25));
    });

    test('el parto real no se registra antes de 100 días', () {
      expect(earliestBirthDate(DateTime(2026, 1, 1)), DateTime(2026, 4, 11));
    });

    test('una gestación está pendiente sin parto y sin marcar como fallida', () {
      expect(isPendingFarrowing({'fecha_parto': null, 'fallida': false}), isTrue);
      expect(isPendingFarrowing({'fecha_parto': null}), isTrue);
      expect(isPendingFarrowing({'fecha_parto': '2026-10-13', 'fallida': false}), isFalse);
      expect(isPendingFarrowing({'fecha_parto': null, 'fallida': true}), isFalse);
    });

    test('la gestación pendiente de una cerda es la más reciente y solo de ella', () {
      final rows = <Map<String, dynamic>>[
        {'id': 'a', 'cerda_id': 's1', 'fecha_monta': '2026-06-01', 'fecha_parto': null, 'fallida': false},
        {'id': 'b', 'cerda_id': 's1', 'fecha_monta': '2026-08-01', 'fecha_parto': null, 'fallida': false},
        {'id': 'c', 'cerda_id': 's1', 'fecha_monta': '2026-09-01', 'fecha_parto': null, 'fallida': true},
        {'id': 'd', 'cerda_id': 's2', 'fecha_monta': '2026-10-01', 'fecha_parto': null, 'fallida': false},
      ];
      expect(pendingFarrowingFor('s1', rows)?['id'], 'b');
      expect(pendingFarrowingFor('s2', rows)?['id'], 'd');
      expect(pendingFarrowingFor('s3', rows), isNull);
    });
  });

  group('alimento', () {
    test('solo los cerdos activos cuentan para la ración', () {
      expect(isActivePig({'estado': 'activo'}), isTrue);
      for (final estado in ['vendido', 'fallecido', 'baja']) {
        expect(isActivePig({'estado': estado}), isFalse);
      }
    });
  });
}
