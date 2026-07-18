import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Papel de tiquete crema con bordes superior e inferior en zigzag (efecto
/// "papel térmico rasgado") y una sombra suave. El [child] se dibuja encima
/// del papel con un padding que respeta los dientes del zigzag.
///
/// Se usa como contenedor de las facturas / historial de mesa en toda la app.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({
    super.key,
    required this.child,
    this.color = AppColors.paper,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.toothHeight = 8,
    this.toothWidth = 16,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  /// Alto de cada diente del zigzag.
  final double toothHeight;

  /// Ancho de cada diente del zigzag.
  final double toothWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ReceiptPainter(
        color: color,
        toothHeight: toothHeight,
        toothWidth: toothWidth,
      ),
      child: Padding(
        // El contenido se separa de los dientes arriba y abajo.
        padding: padding.add(
          EdgeInsets.symmetric(vertical: toothHeight + 8),
        ),
        child: child,
      ),
    );
  }
}

class _ReceiptPainter extends CustomPainter {
  _ReceiptPainter({
    required this.color,
    required this.toothHeight,
    required this.toothWidth,
  });

  final Color color;
  final double toothHeight;
  final double toothWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    // Sombra suave bajo el papel.
    canvas.drawShadow(
      path.shift(const Offset(0, 3)),
      Colors.black.withOpacity(0.35),
      10,
      false,
    );

    canvas.drawPath(path, Paint()..color = color);
  }

  Path _buildPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    // Cantidad de dientes que caben a lo ancho.
    final teeth = (w / toothWidth).floor().clamp(1, 400);
    final step = w / teeth;

    // ── Borde superior (zigzag de izquierda a derecha) ──
    path.moveTo(0, toothHeight);
    for (var i = 0; i < teeth; i++) {
      final x1 = step * i + step / 2;
      final x2 = step * (i + 1);
      path.lineTo(x1, 0);
      path.lineTo(x2, toothHeight);
    }

    // ── Lado derecho ──
    path.lineTo(w, h - toothHeight);

    // ── Borde inferior (zigzag de derecha a izquierda) ──
    for (var i = teeth - 1; i >= 0; i--) {
      final x1 = step * i + step / 2;
      final x2 = step * i;
      path.lineTo(x1, h);
      path.lineTo(x2, h - toothHeight);
    }

    // ── Lado izquierdo ──
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_ReceiptPainter old) =>
      old.color != color ||
      old.toothHeight != toothHeight ||
      old.toothWidth != toothWidth;
}
