"""
Dark Mode Audit v2 — comprehensive fix for hardcoded background colors in base_wallet_screen.dart
that never respond to theme changes.
"""
import re, os

BASE = r'C:/Users/cotes/Documents/Bonanza/lib'


def fix_file(path, replacements):
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()
    orig = c
    for (old, new) in replacements:
        c = c.replace(old, new)
    if c != orig:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)
        print(f"UPDATED: {path}")
    else:
        print(f"NO CHANGE: {path}")


# ─── 1. base_wallet_screen.dart ────────────────────────────────────────────────
# Hardcoded paper-beige surfaces that break in dark mode
wallet = os.path.join(BASE, 'features/base_management/presentation/screens/base_wallet_screen.dart')
fix_file(wallet, [
    # Header gradient: make it theme-aware
    (
        "gradient: LinearGradient(\n          colors: [AppColors.paperSurface, AppColors.paperBackground],\n          begin: Alignment.topCenter,\n          end: Alignment.bottomCenter,\n        ),",
        "gradient: isDark ? AppColors.darkHeaderGradient : AppColors.lightHeaderGradient,"
    ),
    # AlertDialog background: hardcoded light
    (
        "backgroundColor: AppColors.paperSurface,\n      shape: RoundedRectangleBorder(\n        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),\n        side: const BorderSide(color: AppColors.paperBorder),",
        "backgroundColor: Theme.of(context).colorScheme.surface,\n      shape: RoundedRectangleBorder(\n        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),\n        side: BorderSide(color: Theme.of(context).colorScheme.outline),"
    ),
    # BottomSheet container
    (
        "color: AppColors.paperSurface,\n        borderRadius: const BorderRadius.vertical(",
        "color: Theme.of(context).colorScheme.surface,\n        borderRadius: const BorderRadius.vertical("
    ),
    # Quick-amount chip unselected background  
    (
        ": AppColors.paperBackground,\n                      side: BorderSide(",
        ": Theme.of(context).colorScheme.surfaceContainerLowest,\n                      side: BorderSide("
    ),
])

# ─── 2. transfer_capture_screen.dart — Remove bank chip selector ──────────────
transfer = os.path.join(BASE, 'features/payments/presentation/screens/transfer_capture_screen.dart')
with open(transfer, 'r', encoding='utf-8') as f:
    c = f.read()

# Remove the entire bank-chip section (from comment to the closing of its SizedBox)
c = re.sub(
    r'\s*const SizedBox\(height: AppDimensions\.space16\),\s*'
    r'// ── Plataforma \(chips compactos, Nequi por defecto\) ──.*?'
    r'\}\)\.toList\(\),\s*\),\s*const SizedBox\(height: AppDimensions\.space24\),',
    '\n                    const SizedBox(height: AppDimensions.space24),',
    c,
    flags=re.DOTALL
)

# Also update the label text from 'Comprobante por' to 'Comprobante de Transferencia –'
c = c.replace(
    "'Comprobante por ${billSubtotal.toCop}'",
    "'Comprobante de Transferencia · ${billSubtotal.toCop}'"
)

with open(transfer, 'w', encoding='utf-8') as f:
    f.write(c)
print(f"UPDATED: {transfer}")

# ─── 3. radar_screen.dart — Tab container background in dark mode ─────────────
radar = os.path.join(BASE, 'features/radar/presentation/screens/radar_screen.dart')
fix_file(radar, [
    # Tab switcher background should use surfaceContainer not hardcoded
    (
        "const selectedFg = Colors.white;",
        "const selectedFg = Colors.white;"  # white on amber is fine, keep it
    ),
])

# ─── 4. tables/table_history_detail: Colors.black fix ────────────────────────
thd = os.path.join(BASE, 'features/tables/presentation/screens/table_history_detail_screen.dart')
fix_file(thd, [
    (
        "? Colors.black\n        : (isDark ? Colors.white70 : Colors.black87);",
        "? Theme.of(context).colorScheme.onSurface\n        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant);"
    ),
])

print("Done.")
