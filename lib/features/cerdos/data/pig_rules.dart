/// Peso máximo aceptado para un cerdo, en kg (un semental grande ronda los 400).
const maxPigWeightKg = 400;

/// Valida el texto del peso (coma o punto decimal): vacío es válido, y si se
/// captura debe ser mayor que 0 y no pasar de [maxPigWeightKg].
String? validatePigWeight(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final weight = double.tryParse(text.replaceAll(',', '.'));
  if (weight == null) return 'Peso inválido';
  if (weight <= 0) return 'El peso debe ser mayor que 0';
  if (weight > maxPigWeightKg) return 'El peso máximo es $maxPigWeightKg kg';
  return null;
}

/// Razas del menú desplegable; la opción [otherBreed] permite escribir otra.
const pigBreeds = [
  'Duroc',
  'Yorkshire',
  'Landrace',
  'Hampshire',
  'Pietrain',
  'Criollo',
];

/// Opción del menú que abre un campo de texto para una raza que no está en la lista.
const otherBreed = 'Otra';

String _breedKey(String value) {
  const from = 'áéíóú';
  const to = 'aeiou';
  var key = value.trim().toLowerCase();
  for (var i = 0; i < from.length; i++) {
    key = key.replaceAll(from[i], to[i]);
  }
  return key;
}

/// Cómo se muestra en el menú una raza ya guardada: si coincide con una de la
/// lista (sin importar mayúsculas ni acentos, así "duroc" es "Duroc") usa esa;
/// si no, queda como [otherBreed] con el texto original; vacía no elige nada.
({String? opcion, String otra}) breedSelectionFor(String? saved) {
  final text = saved?.trim() ?? '';
  if (text.isEmpty) return (opcion: null, otra: '');
  final key = _breedKey(text);
  for (final breed in pigBreeds) {
    if (_breedKey(breed) == key) return (opcion: breed, otra: '');
  }
  return (opcion: otherBreed, otra: text);
}

/// Raza que se guarda según lo elegido en el menú (y el texto si fue "Otra").
String? breedToSave({required String? opcion, required String otra}) {
  if (opcion == null) return null;
  if (opcion != otherBreed) return opcion;
  final text = otra.trim();
  if (text.isEmpty) return null;
  final match = breedSelectionFor(text);
  return match.opcion == otherBreed ? text : match.opcion;
}

/// Si se elige "Otra", la raza escrita es obligatoria y de largo razonable.
String? validateOtherBreed(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe la raza';
  if (text.length > 40) return 'La raza es demasiado larga';
  return null;
}

/// Nombre del cerdo (opcional): no puede ser solo números, porque se confunde
/// con un arete, ni coincidir con el arete de otro cerdo ([aretes]).
String? validatePigName(String? value, {Iterable<String> aretes = const []}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (RegExp(r'^\d+$').hasMatch(text)) {
    return 'El nombre no puede ser solo números (se confunde con un arete)';
  }
  final lower = text.toLowerCase();
  if (aretes.any((arete) => arete.trim().toLowerCase() == lower)) {
    return 'Ese nombre ya es el arete de otro cerdo';
  }
  return null;
}

/// Al registrar un cerdo nuevo hay que elegir corral; al editar uno que ya
/// estaba sin corral no se bloquea.
String? validatePenChoice(String? penId, {required bool isNewPig}) =>
    isNewPig && penId == null ? 'Elige un corral' : null;

/// Días después de una inseminación (monta) en los que macho y hembra pueden
/// compartir corral; fuera de esa ventana se pelean.
const mountingWindowDays = 3;

/// ¿Alguna de las cerdas [sowIds] tuvo una monta (inseminación) en los últimos
/// [mountingWindowDays] días? [farrowings] son los registros de la tabla partos.
bool hasRecentMating({
  required Iterable<String> sowIds,
  required Iterable<Map<String, dynamic>> farrowings,
  DateTime? hoy,
}) {
  final now = hoy ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sows = sowIds.toSet();
  for (final row in farrowings) {
    if (!sows.contains(row['cerda_id'])) continue;
    final mating = DateTime.tryParse('${row['fecha_monta']}');
    if (mating == null) continue;
    final days = today
        .difference(DateTime(mating.year, mating.month, mating.day))
        .inDays;
    if (days >= 0 && days <= mountingWindowDays) return true;
  }
  return false;
}

/// Problema de convivencia de sexos en un corral. Si [blocks] es true no se
/// puede guardar; si no, se avisa y quien captura decide si guardar así.
class SexMixProblem {
  const SexMixProblem(this.message, {required this.blocks});

  final String message;
  final bool blocks;
}

/// Revisa si el cerdo de [sexo] puede ir al corral [penName] de etapa [stage]:
/// - Un macho nunca va en un corral de Gestación (estresa a las cerdas).
/// - Macho y hembra juntos solo se justifican durante la monta; fuera de ella
///   se pelean, así que se avisa si no hay una inseminación reciente.
/// [residentSexes] son los sexos de los cerdos activos que ya están en el corral.
SexMixProblem? checkSexMix({
  required String sexo,
  required String stage,
  required String penName,
  required Iterable<String> residentSexes,
  required bool recentMating,
}) {
  final hasMale = residentSexes.contains('macho');
  final hasFemale = residentSexes.contains('hembra');
  if (stage == 'gestacion') {
    if (sexo == 'macho') {
      return SexMixProblem(
        'Un macho no puede ir en el corral $penName (Gestación): '
        'estresa a las cerdas gestantes. Elige otro corral.',
        blocks: true,
      );
    }
    if (hasMale) {
      return SexMixProblem(
        'El corral $penName (Gestación) tiene un macho, y junto a una hembra '
        'gestante la estresa. Conviene mover al macho antes.',
        blocks: false,
      );
    }
    return null;
  }
  final mixes = (sexo == 'macho' && hasFemale) || (sexo == 'hembra' && hasMale);
  if (mixes && !recentMating) {
    return SexMixProblem(
      'Macho y hembra juntos solo se justifican durante la monta; fuera de '
      'ella se pelean. En el corral $penName no hay una inseminación '
      'registrada en los últimos $mountingWindowDays días.',
      blocks: false,
    );
  }
  return null;
}

/// Motivos por los que un cerdo puede quedar sin corral. Con [otherNoPenReason]
/// se escribe uno distinto.
const noPenReasons = [
  'Venta',
  'Matadero',
  'Fallecimiento',
  'Cuarentena o enfermería',
  'Traslado a otra granja',
];

/// Opción del menú de motivos que abre un campo de texto.
const otherNoPenReason = 'Otro';

/// Estado que conviene al motivo: una venta es 'vendido', el matadero es 'baja'
/// y un fallecimiento es 'fallecido'. Los demás motivos no cambian el estado.
String? estadoSugeridoPorMotivo(String? motivo) => switch (motivo) {
  'Venta' => 'vendido',
  'Matadero' => 'baja',
  'Fallecimiento' => 'fallecido',
  _ => null,
};

/// Cómo se muestra en el menú un motivo ya guardado: si es de la lista usa esa
/// opción; si no, queda como [otherNoPenReason] con el texto original.
({String? opcion, String otro}) noPenReasonSelectionFor(String? saved) {
  final text = saved?.trim() ?? '';
  if (text.isEmpty) return (opcion: null, otro: '');
  for (final reason in noPenReasons) {
    if (reason.toLowerCase() == text.toLowerCase()) {
      return (opcion: reason, otro: '');
    }
  }
  return (opcion: otherNoPenReason, otro: text);
}

/// Motivo que se guarda: solo si el cerdo queda sin corral; con corral es null.
String? noPenReasonToSave({
  required String? corralId,
  required String? opcion,
  required String otro,
}) {
  if (corralId != null || opcion == null) return null;
  if (opcion != otherNoPenReason) return opcion;
  final text = otro.trim();
  return text.isEmpty ? null : text;
}

/// Un cerdo sin corral ([needsReason]) tiene que elegir por qué.
String? validateNoPenReasonChoice(String? opcion, {required bool needsReason}) =>
    needsReason && opcion == null ? 'Indica por qué no tiene corral' : null;

/// Si el motivo es "Otro", hay que escribirlo (hasta 60 letras).
String? validateNoPenReasonText(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe el motivo';
  if (text.length > 60) return 'El motivo es demasiado largo (máximo 60)';
  return null;
}

/// Texto del corral en listas y detalle: su nombre, o el motivo si no tiene.
String penLabelFor({String? penName, String? motivo}) {
  if (penName != null) return penName;
  final reason = motivo?.trim() ?? '';
  return reason.isEmpty ? 'Sin corral · falta el motivo' : 'Sin corral ($reason)';
}

/// Un corral admite otro cerdo activo solo si no está lleno.
bool penHasRoom({required int capacity, required int activeResidents}) =>
    activeResidents < capacity;

/// Peso máximo razonable para la edad: ~2 kg al nacer y hasta ~1.3 kg de
/// ganancia por día (ya engordando bien), sin pasar de [maxPigWeightKg].
double maxPlausibleWeightKg(int ageDays) {
  final limit = 2 + ageDays * 1.3;
  return limit > maxPigWeightKg ? maxPigWeightKg.toDouble() : limit;
}

/// Aviso (no bloquea) cuando el peso no cuadra con la edad, por ejemplo un
/// cerdo de 6 días con 77 kg. Devuelve null si no hay datos o todo es creíble.
String? pesoIncoherenteConEdad({
  required double? pesoKg,
  required DateTime? nacimiento,
  DateTime? hoy,
}) {
  if (pesoKg == null || nacimiento == null) return null;
  final now = hoy ?? DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(nacimiento.year, nacimiento.month, nacimiento.day))
      .inDays;
  if (days < 0) return null;
  final edad = days == 1 ? '1 día' : '$days días';
  final capturado =
      pesoKg.toStringAsFixed(pesoKg % 1 == 0 ? 0 : 1);
  // Hasta los 180 días se compara con el rango de referencia; después, solo
  // con el máximo creíble.
  final referencia = pesoReferenciaPorEdad(nacimiento, hoy: now);
  if (referencia != null) {
    if (pesoKg <= referencia.maxKg) return null;
    return 'Un cerdo de $edad de nacido normalmente pesa entre '
        '${referencia.minKg.toStringAsFixed(1)} y '
        '${referencia.maxKg.toStringAsFixed(1)} kg, y capturaste $capturado kg. '
        '¿Quieres revisar el peso o la fecha de nacimiento?';
  }
  final limit = maxPlausibleWeightKg(days);
  if (pesoKg <= limit) return null;
  return 'Un cerdo de $edad de nacido normalmente no pesa más de '
      '${limit.round()} kg, y capturaste $capturado kg. '
      '¿Quieres revisar el peso o la fecha de nacimiento?';
}

/// Peso de referencia (aproximado) de un cerdo según sus días de nacido.
class PesoReferencia {
  const PesoReferencia({
    required this.dias,
    required this.minKg,
    required this.maxKg,
  });

  final int dias;
  final double minKg;
  final double maxKg;
}

/// Curva orientativa de crecimiento: ~1.5 kg al nacer, ~8.5 kg a los 28 días,
/// ~27 kg a los 70 y ~87 kg a los 150. El rango es ±20 % (más 0.5 kg arriba). Después de 180 días
/// el peso varía mucho (engorda, reproductores) y no se da referencia.
PesoReferencia? pesoReferenciaPorEdad(DateTime? nacimiento, {DateTime? hoy}) {
  if (nacimiento == null) return null;
  final now = hoy ?? DateTime.now();
  final dias = DateTime(now.year, now.month, now.day)
      .difference(DateTime(nacimiento.year, nacimiento.month, nacimiento.day))
      .inDays;
  if (dias < 0 || dias > 180) return null;
  final double esperado;
  if (dias <= 28) {
    esperado = 1.5 + 0.25 * dias;
  } else if (dias <= 70) {
    esperado = 8.5 + 0.45 * (dias - 28);
  } else if (dias <= 150) {
    esperado = 27.4 + 0.75 * (dias - 70);
  } else {
    esperado = 87.4 + 0.85 * (dias - 150);
  }
  final maxKg = esperado * 1.2 + 0.5; // margen para camadas pesadas
  final limite = maxPlausibleWeightKg(dias);
  return PesoReferencia(
    dias: dias,
    minKg: esperado * 0.8,
    maxKg: maxKg > limite ? limite : maxKg,
  );
}
