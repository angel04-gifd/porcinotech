/// Veces que se le da de comer a un corral por día (hay que racionar).
const maxFeedingsPerDay = 3;

String feedingDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Comidas ya registradas ese día para un corral (null = "todos los corrales"),
/// sin importar el tipo de alimento.
int feedingsOn(
  Iterable<Map<String, dynamic>> records, {
  required String? penId,
  required String fecha,
}) => records
    .where((r) => r['fecha'] == fecha && r['corral_id'] == penId)
    .length;

/// Ids de las comidas que pasan de [maxFeedingsPerDay] en su corral y día
/// (la 4.ª, 5.ª… por orden de registro), para ofrecer borrarlas.
Set<String> extraFeedingIds(List<Map<String, dynamic>> records) {
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final r in records) {
    groups.putIfAbsent('${r['corral_id']}|${r['fecha']}', () => []).add(r);
  }
  final extras = <String>{};
  for (final group in groups.values) {
    group.sort(
      (a, b) => '${a['created_at']}'.compareTo('${b['created_at']}'),
    );
    for (var i = maxFeedingsPerDay; i < group.length; i++) {
      extras.add(group[i]['id'] as String);
    }
  }
  return extras;
}
