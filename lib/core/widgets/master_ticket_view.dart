import 'package:flutter/material.dart';
import 'receipt_paper.dart';

/// Componente global para renderizar tickets/recibos de papel.
/// Sigue la regla inmutable: el papel físico nunca cambia a modo oscuro.
class MasterTicketView extends StatelessWidget {
  const MasterTicketView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.toothHeight = 8,
    this.toothWidth = 16,
    this.isStub = false,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsets padding;
  final double toothHeight;
  final double toothWidth;
  
  /// Si es true, usa el diseño de talón (ReceiptStub), con zigzag solo abajo.
  final bool isStub;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;

    // REGLA DE COLORES:
    // 1. TONO PRINCIPAL (Fuerte, Brillante y Destacado)
    final Color primaryInk = isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1E1C1A);
    // 2. TONO SECUNDARIO (Suave y Apagado)
    final Color secondaryInk = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF7A7269);
    // 3. LÍNEAS SEPARADORAS
    final Color dividerColor = isDark ? Colors.white24 : Colors.black26;

    // Fondo del tiquete según el tema
    final Color ticketBgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFDF9);

    final ticketTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: ticketBgColor,
      colorScheme: baseTheme.colorScheme.copyWith(
        surface: ticketBgColor,
        onSurface: primaryInk,
        onSurfaceVariant: secondaryInk,
        outlineVariant: dividerColor,
      ),
      iconTheme: baseTheme.iconTheme.copyWith(color: primaryInk),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: primaryInk,
        displayColor: primaryInk,
      ),
      dividerColor: dividerColor,
    );

    final paperWidget = isStub
        ? ReceiptStub(
            color: ticketBgColor,
            padding: padding,
            toothHeight: toothHeight,
            toothWidth: toothWidth,
            onTap: onTap,
            onLongPress: onLongPress,
            child: child,
          )
        : ReceiptPaper(
            color: ticketBgColor,
            padding: padding,
            toothHeight: toothHeight,
            toothWidth: toothWidth,
            child: child,
          );

    return Theme(
      data: ticketTheme,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: primaryInk),
        child: IconTheme(
          data: IconThemeData(color: primaryInk),
          child: paperWidget,
        ),
      ),
    );
  }
}
