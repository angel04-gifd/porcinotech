/// Formatos de foto de perfil aceptados.
const avatarExtensions = ['jpg', 'jpeg', 'png', 'webp'];

/// Tamaño máximo de la foto subida: 2 MB (el mismo límite del bucket).
const maxAvatarBytes = 2 * 1024 * 1024;

/// Extensión válida del nombre de archivo, en minúsculas, o null si no es una
/// imagen aceptada.
String? avatarExtensionFor(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;
  final ext = fileName.substring(dot + 1).toLowerCase();
  return avatarExtensions.contains(ext) ? ext : null;
}

/// Tipo de contenido que se envía al guardar la foto.
String avatarContentType(String extension) => switch (extension.toLowerCase()) {
  'png' => 'image/png',
  'webp' => 'image/webp',
  _ => 'image/jpeg',
};

/// Ruta de la foto en el bucket: una carpeta por usuario (las reglas de
/// Supabase solo dejan escribir en la propia).
String avatarStoragePath(String userId, String extension) =>
    '$userId/avatar.${extension.toLowerCase()}';

/// Todas las rutas posibles de la foto de un usuario, para borrar la anterior
/// cuando cambia de formato.
List<String> avatarStoragePaths(String userId) => [
  for (final ext in avatarExtensions) avatarStoragePath(userId, ext),
];

/// Revisa el tamaño de la foto elegida; null si es válida.
String? validateAvatarBytes(int length) {
  if (length <= 0) return 'No se pudo leer la foto.';
  if (length > maxAvatarBytes) return 'La foto pesa más de 2 MB. Elige una más ligera.';
  return null;
}

/// Foto que se muestra: la subida por el usuario, luego la de Google y, si no
/// hay ninguna, null (se usan las iniciales).
String? pickAvatarUrl({String? uploaded, String? google}) {
  final own = uploaded?.trim() ?? '';
  if (own.isNotEmpty) return own;
  final fromGoogle = google?.trim() ?? '';
  return fromGoogle.isEmpty ? null : fromGoogle;
}

/// Título del aviso que se muestra antes de abrir la galería o la cámara.
String photoPermissionTitle({required bool camera}) =>
    camera ? '¿Abrir la cámara?' : '¿Abrir tu galería?';

/// Texto del aviso: explica qué se va a abrir y que solo se sube la foto elegida.
String photoPermissionMessage({required bool camera}) => camera
    ? 'PorcinoTech usará la cámara para tomar tu foto de perfil. '
        'Solo se guardará la foto que tomes.'
    : 'PorcinoTech abrirá tu galería para que elijas tu foto de perfil. '
        'Solo se guardará la foto que selecciones; el resto de tus fotos no se comparte.';
