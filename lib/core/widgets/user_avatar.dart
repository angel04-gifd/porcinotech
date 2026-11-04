import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';

/// Iniciales para el avatar: las dos primeras letras del nombre ("Angel Jovani"
/// → "AJ"); sin nombre, la primera letra del correo; sin nada, "?".
String userInitials({String? name, String? email}) {
  final words = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isNotEmpty) {
    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }
  final mail = (email ?? '').trim();
  if (mail.isNotEmpty) return String.fromCharCode(mail.runes.first).toUpperCase();
  return '?';
}

/// Avatar de la cuenta: la foto de Google si existe y, si no (o si no carga),
/// las iniciales del nombre o del correo.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.radius = 16});

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(currentUserAvatarProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final email = ref.watch(currentUserEmailProvider);
    final initials = Text(
      userInitials(name: profile?['nombre'] as String?, email: email),
      style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w600),
    );
    return CircleAvatar(
      radius: radius,
      child: url == null
          ? initials
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: initials),
              ),
            ),
    );
  }
}
