import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppToastType { success, error, info }

/// Feedback superior no intrusivo: un banner que baja desde arriba, se mantiene
/// ~2.5s y sube. Reemplaza los SnackBar de abajo (que molestan sobre botones).
abstract final class AppToast {
  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  static void success(
    BuildContext context,
    String m, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      show(context, m,
          type: AppToastType.success, actionLabel: actionLabel, onAction: onAction);
  static void error(BuildContext context, String m) =>
      show(context, m, type: AppToastType.error);
  static void info(BuildContext context, String m) =>
      show(context, m, type: AppToastType.info);
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _ctrl.forward();
    // Con acción "Deshacer" se deja más tiempo para que el usuario alcance a tocar.
    final visible = widget.onAction != null
        ? const Duration(milliseconds: 4000)
        : const Duration(milliseconds: 2400);
    await Future<void>.delayed(visible);
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  void _handleAction() {
    widget.onAction?.call();
    if (mounted) _dismissNow();
  }

  Future<void> _dismissNow() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, IconData icon}) get _style => switch (widget.type) {
        AppToastType.success => (
            bg: AppColors.secondaryDark,
            fg: Colors.white,
            icon: Icons.check_circle_rounded
          ),
        AppToastType.error => (
            bg: AppColors.statusRed,
            fg: Colors.white,
            icon: Icons.error_rounded
          ),
        AppToastType.info => (
            bg: AppColors.primary,
            fg: const Color(0xFF241A05),
            icon: Icons.info_rounded
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final topInset = MediaQuery.of(context).padding.top;
    final hasAction = widget.actionLabel != null && widget.onAction != null;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !hasAction,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_anim),
          child: FadeTransition(
            opacity: _anim,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(s.icon, color: s.fg, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: s.fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasAction)
                        TextButton(
                          onPressed: _handleAction,
                          style: TextButton.styleFrom(
                            foregroundColor: s.fg,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            widget.actionLabel!.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: s.fg,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
