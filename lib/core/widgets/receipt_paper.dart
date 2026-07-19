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

/// Talón de tiquete compacto: papel crema con borde superior recto (redondeado
/// leve) y zigzag SOLO abajo — como un tiquete arrancado del talonario.
/// Usado por las tarjetas de mesa y otras vistas compactas.
class ReceiptStub extends StatelessWidget {
  const ReceiptStub({
    super.key,
    required this.child,
    this.color = AppColors.paper,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 8),
    this.toothHeight = 7,
    this.toothWidth = 14,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double toothHeight;
  final double toothWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final stub = CustomPaint(
      painter: _StubPainter(
        color: color,
        toothHeight: toothHeight,
        toothWidth: toothWidth,
      ),
      child: Padding(
        padding: padding.add(EdgeInsets.only(bottom: toothHeight + 4)),
        child: child,
      ),
    );
    if (onTap == null && onLongPress == null) return stub;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: stub,
    );
  }
}

class _StubPainter extends CustomPainter {
  _StubPainter({
    required this.color,
    required this.toothHeight,
    required this.toothWidth,
  });

  final Color color;
  final double toothHeight;
  final double toothWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = 6.0; // radio superior leve

    final teeth = (w / toothWidth).floor().clamp(1, 200);
    final step = w / teeth;

    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - toothHeight);
    // Zigzag inferior (derecha → izquierda).
    for (var i = teeth - 1; i >= 0; i--) {
      path.lineTo(step * i + step / 2, h);
      path.lineTo(step * i, h - toothHeight);
    }
    path.close();

    canvas.drawShadow(
      path.shift(const Offset(0, 2)),
      Colors.black.withOpacity(0.3),
      6,
      false,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StubPainter old) =>
      old.color != color ||
      old.toothHeight != toothHeight ||
      old.toothWidth != toothWidth;
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
