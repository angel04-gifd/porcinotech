import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Botón «Iniciar sesión con Google»: fondo blanco, borde gris y la «G» de
/// colores, como pide la guía de marca de Google. Se ve igual en tema claro
/// y oscuro.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: const Color(0xFFF2F2F2),
          disabledForegroundColor: const Color(0xFF9E9E9E),
          side: const BorderSide(color: Color(0xFF747775)),
          shape: const StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoogleLogo(size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo «G» de Google dibujado con código (no necesita imagen ni paquetes).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _GoogleLogoPainter()),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.22;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);

    double rad(double degrees) => degrees * math.pi / 180;

    void arc(Color color, double startDeg, double sweepDeg) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      // 1° extra para que no quede una línea clara entre colores.
      canvas.drawArc(rect, rad(startDeg), rad(sweepDeg + 1), false, paint);
    }

    // Los ángulos van en sentido horario desde las 3 en punto.
    arc(_red, 220, 100); // arriba
    arc(_yellow, 130, 90); // izquierda
    arc(_green, 40, 90); // abajo
    arc(_blue, 0, 40); // abajo a la derecha

    // Barra horizontal azul de la «G».
    canvas.drawRect(
      Rect.fromLTRB(s / 2, s / 2 - stroke / 2, s, s / 2 + stroke / 2),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
