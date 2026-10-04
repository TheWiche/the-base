import re

with open('lib/core/widgets/receipt_paper.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix ReceiptPaper
content = re.sub(
    r'(?s)(class ReceiptPaper extends StatelessWidget \{.*?@override\s+Widget build\(BuildContext context\) \{)(\s*// RepaintBoundary.*?return RepaintBoundary\(\s*child: CustomPaint\(\s*painter: _ReceiptPainter\(\s*color: color,\s*toothHeight: toothHeight,\s*toothWidth: toothWidth,\s*\),\s*child: Padding\(\s*padding: padding\.add\(\s*EdgeInsets\.symmetric\(vertical: toothHeight \+ 8\),\s*\),\s*child: child,\s*\),\s*\),\s*\);)',
    r'''\1
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useDarkTicket = isDark && color == AppColors.paper;
    final effectiveColor = useDarkTicket ? const Color(0xFF252628) : color;
    
    final theme = Theme.of(context);
    final paperTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        onSurface: useDarkTicket ? Colors.white : AppColors.ink,
        onSurfaceVariant: useDarkTicket ? const Color(0xFFA0A0A5) : AppColors.inkSecondary,
      ),
    );

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ReceiptPainter(
          color: effectiveColor,
          toothHeight: toothHeight,
          toothWidth: toothWidth,
        ),
        child: Theme(
          data: paperTheme,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: paperTheme.colorScheme.onSurface),
            child: Padding(
              padding: padding.add(EdgeInsets.symmetric(vertical: toothHeight + 8)),
              child: child,
            ),
          ),
        ),
      ),
    );''',
    content
)

# Fix ReceiptStub
content = re.sub(
    r'(?s)(class ReceiptStub extends StatelessWidget \{.*?@override\s+Widget build\(BuildContext context\) \{)(\s*final stub = RepaintBoundary\(\s*child: CustomPaint\(\s*painter: _StubPainter\(\s*color: color,\s*toothHeight: toothHeight,\s*toothWidth: toothWidth,\s*\),\s*child: Padding\(\s*padding: padding\.add\(EdgeInsets\.only\(bottom: toothHeight \+ 4\)\),\s*child: child,\s*\),\s*\),\s*\);)',
    r'''\1
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useDarkTicket = isDark && color == AppColors.paper;
    final effectiveColor = useDarkTicket ? const Color(0xFF252628) : color;
    
    final theme = Theme.of(context);
    final paperTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        onSurface: useDarkTicket ? Colors.white : AppColors.ink,
        onSurfaceVariant: useDarkTicket ? const Color(0xFFA0A0A5) : AppColors.inkSecondary,
      ),
    );

    final stub = RepaintBoundary(
      child: CustomPaint(
        painter: _StubPainter(
          color: effectiveColor,
          toothHeight: toothHeight,
          toothWidth: toothWidth,
        ),
        child: Theme(
          data: paperTheme,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: paperTheme.colorScheme.onSurface),
            child: Padding(
              padding: padding.add(EdgeInsets.only(bottom: toothHeight + 4)),
              child: child,
            ),
          ),
        ),
      ),
    );''',
    content
)

with open('lib/core/widgets/receipt_paper.dart', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/core/widgets/receipt_widgets.dart', 'r', encoding='utf-8') as f:
    content2 = f.read()

# Fix ReceiptRow
content2 = re.sub(
    r'class ReceiptRow extends StatelessWidget \{.*?this\.color = AppColors\.paperInk,',
    r'class ReceiptRow extends StatelessWidget {\n  const ReceiptRow({\n    super.key,\n    required this.label,\n    required this.value,\n    this.bold = false,\n    this.color,\n',
    content2, flags=re.DOTALL
)
content2 = re.sub(
    r'final Color color;',
    r'final Color? color;',
    content2
)
content2 = re.sub(
    r'final style = \(bold \? AppTextStyles\.receiptBodyBold : AppTextStyles\.receiptBody\)\n\s*\.copyWith\(color: color\);',
    r'final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;\n    final style = (bold ? AppTextStyles.receiptBodyBold : AppTextStyles.receiptBody)\n        .copyWith(color: effectiveColor);',
    content2
)

# Fix PillToggle
content2 = re.sub(
    r'const track = Color\(0xFFEFE9DC\); // Papel crema cálido\s*const inactive = AppColors\.inkSecondary;',
    r'''final _isDark = Theme.of(context).brightness == Brightness.dark;
      final track = _isDark ? const Color(0xFF1C1D1F) : const Color(0xFFEFE9DC);
      final inactive = _isDark ? const Color(0xFF9CA3AF) : AppColors.inkSecondary;
      final activeBg = _isDark ? const Color(0xFFD97706) : AppColors.primary;
      final activeShadow = activeBg.withValues(alpha: 0.28);
      final borderColor = _isDark ? const Color(0xFF2A2B2E) : AppColors.paperBorder;''',
    content2
)

content2 = re.sub(r'color: AppColors\.paperBorder,', r'color: borderColor,', content2)
content2 = re.sub(r'color: AppColors\.primary,', r'color: activeBg,', content2)
content2 = re.sub(r'color: AppColors\.primary\.withValues\(alpha: 0\.28\),', r'color: activeShadow,', content2)

with open('lib/core/widgets/receipt_widgets.dart', 'w', encoding='utf-8') as f:
    f.write(content2)

with open('lib/features/dashboard/presentation/screens/legalization_screen.dart', 'r', encoding='utf-8') as f:
    content3 = f.read()

content3 = re.sub(r'AppColors\.paperInkSoft', r'Theme.of(context).colorScheme.onSurfaceVariant', content3)
content3 = re.sub(r'AppColors\.paperInk', r'Theme.of(context).colorScheme.onSurface', content3)

with open('lib/features/dashboard/presentation/screens/legalization_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content3)
