import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Línea divisoria punteada estilo tiquete (guiones horizontales).
class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.color = AppColors.paperLine,
    this.dashWidth = 5,
    this.dashGap = 4,
    this.thickness = 1.4,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final Color color;
  final double dashWidth;
  final double dashGap;
  final double thickness;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: thickness,
        width: double.infinity,
        child: CustomPaint(
          painter: _DashedLinePainter(
            color: color,
            dashWidth: dashWidth,
            dashGap: dashGap,
            thickness: thickness,
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashGap,
    required this.thickness,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.thickness != thickness;
}

/// Línea de tiquete: etiqueta a la izquierda, valor a la derecha, ambos en
/// tipografía monoespaciada (tinta de papel).
class ReceiptRow extends StatelessWidget {
  const ReceiptRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.color = AppColors.paperInk,
    this.labelMaxLines = 2,
  });

  final String label;
  final String value;
  final bool bold;
  final Color color;
  final int labelMaxLines;

  @override
  Widget build(BuildContext context) {
    final style = (bold ? AppTextStyles.receiptBodyBold : AppTextStyles.receiptBody)
        .copyWith(color: color);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: style, maxLines: labelMaxLines, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text(value, style: style),
      ],
    );
  }
}

/// Segmentado tipo píldora (Cronológica / Agrupada). Píldora ámbar animada
/// sobre pista oscura.
class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.isDark = true,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final track = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
    final inactive = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final segW = w / options.length;
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(
                  options.length == 1
                      ? 0
                      : -1 + (2 * selectedIndex / (options.length - 1)),
                  0,
                ),
                child: Container(
                  width: segW,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
              ),
              Row(
                children: List.generate(options.length, (i) {
                  final selected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          options[i],
                          style: AppTextStyles.labelMedium.copyWith(
                            color: selected ? const Color(0xFF241A05) : inactive,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
