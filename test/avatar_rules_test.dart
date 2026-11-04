import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/features/profile/data/avatar_rules.dart';

/// Reglas de la foto de perfil: formato, tamaño, ruta y cuál se muestra.
void main() {
  group('formato de la foto', () {
    test('acepta jpg, jpeg, png y webp sin importar mayúsculas', () {
      expect(avatarExtensionFor('foto.jpg'), 'jpg');
      expect(avatarExtensionFor('FOTO.JPEG'), 'jpeg');
      expect(avatarExtensionFor('mi.foto.PNG'), 'png');
      expect(avatarExtensionFor('a.webp'), 'webp');
    });

    test('rechaza otros formatos o nombres sin extensión', () {
      expect(avatarExtensionFor('video.mp4'), isNull);
      expect(avatarExtensionFor('documento.pdf'), isNull);
      expect(avatarExtensionFor('sin_extension'), isNull);
      expect(avatarExtensionFor('termina_en_punto.'), isNull);
      expect(avatarExtensionFor(''), isNull);
    });

    test('el tipo de contenido sigue a la extensión', () {
      expect(avatarContentType('png'), 'image/png');
      expect(avatarContentType('WEBP'), 'image/webp');
      expect(avatarContentType('jpg'), 'image/jpeg');
      expect(avatarContentType('jpeg'), 'image/jpeg');
    });
  });

  group('tamaño de la foto', () {
    test('una foto normal es válida', () {
      expect(validateAvatarBytes(300 * 1024), isNull);
      expect(validateAvatarBytes(maxAvatarBytes), isNull);
    });

    test('vacía o de más de 2 MB se rechaza', () {
      expect(validateAvatarBytes(0), isNotNull);
      expect(validateAvatarBytes(maxAvatarBytes + 1), contains('2 MB'));
    });
  });

  group('ruta en el bucket', () {
    test('cada usuario escribe en su propia carpeta', () {
      expect(avatarStoragePath('abc-123', 'JPG'), 'abc-123/avatar.jpg');
    });

    test('lista todas las rutas posibles para borrar la anterior', () {
      expect(avatarStoragePaths('u1'), [
        'u1/avatar.jpg',
        'u1/avatar.jpeg',
        'u1/avatar.png',
        'u1/avatar.webp',
      ]);
    });
  });

  group('qué foto se muestra', () {
    test('la subida por el usuario gana sobre la de Google', () {
      expect(
        pickAvatarUrl(uploaded: 'https://x/mia.jpg', google: 'https://g/foto'),
        'https://x/mia.jpg',
      );
    });

    test('sin foto propia se usa la de Google', () {
      expect(pickAvatarUrl(uploaded: null, google: 'https://g/foto'), 'https://g/foto');
      expect(pickAvatarUrl(uploaded: '  ', google: 'https://g/foto'), 'https://g/foto');
    });

    test('sin ninguna devuelve null para usar las iniciales', () {
      expect(pickAvatarUrl(), isNull);
      expect(pickAvatarUrl(uploaded: '', google: ' '), isNull);
    });
  });
}
