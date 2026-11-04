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
