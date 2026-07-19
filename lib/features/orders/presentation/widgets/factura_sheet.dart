import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../tables/domain/entities/table_session_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../providers/order_providers.dart';
import 'receipt_view.dart';

/// Hoja modal de "Factura": tiquete con toggle Cronológica / Agrupada y opción
/// de compartir como imagen o texto.
class FacturaSheet extends ConsumerStatefulWidget {
  const FacturaSheet({super.key, required this.sessionId});

  final int sessionId;

  static Future<void> show(BuildContext context, int sessionId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FacturaSheet(sessionId: sessionId),
    );
  }

  @override
  ConsumerState<FacturaSheet> createState() => _FacturaSheetState();
}

class _FacturaSheetState extends ConsumerState<FacturaSheet> {
  final _boundaryKey = GlobalKey();
  int _mode = 0; // 0 = cronológica, 1 = agrupada
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final items = ref.watch(tableOrderProvider(widget.sessionId)).valueOrNull ?? [];
    final session = ref.watch(tableSessionByIdProvider(widget.sessionId));
    final barName = ref.watch(barNameProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Toggle Cronológica / Agrupada ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PillToggle(
                options: const ['Cronológica', 'Agrupada'],
                selectedIndex: _mode,
                onChanged: (i) => setState(() => _mode = i),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),
            // ── Tiquete ──
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: ReceiptPaper(
                    child: session == null
                        ? const SizedBox.shrink()
                        : _ReceiptContent(
                            barName: barName,
                            session: session,
                            items: items,
                            grouped: _mode == 1,
                          ),
                  ),
                ),
              ),
            ),
            // ── Compartir ──
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: _sharing || session == null
                      ? null
                      : () => _showShareOptions(session, items, barName),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(
                    _sharing ? 'Compartiendo…' : 'Compartir factura',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: const Color(0xFF241A05)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(
    TableSessionEntity session,
    List<OrderItemEntity> items,
    String barName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_rounded, color: AppColors.primary),
              title: Text('Imagen', style: AppTextStyles.titleMedium),
              subtitle: Text('Comparte el tiquete como foto',
                  style: AppTextStyles.bodySmall),
              onTap: () {
                Navigator.of(ctx).pop();
                _shareAsImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notes_rounded, color: AppColors.primary),
              title: Text('Texto', style: AppTextStyles.titleMedium),
              subtitle: Text('Comparte el tiquete como texto',
                  style: AppTextStyles.bodySmall),
              onTap: () {
                Navigator.of(ctx).pop();
                _shareAsText(session, items, barName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsImage() async {
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/factura_${DateTime.now().millisecondsSinceEpoch}.png')
          .writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar la imagen.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareAsText(
    TableSessionEntity session,
    List<OrderItemEntity> items,
    String barName,
  ) async {
    final text = buildReceiptText(
      barName: barName,
      tableNumber: session.tableNumber,
      apodo: session.apodo,
      openedAt: session.openedAt,
      items: items,
      grouped: _mode == 1,
    );
    await Share.share(text, subject: 'Factura Mesa ${session.tableNumber}');
  }
}

// dart:io File via conditional-free import.
// (path_provider ya trae dart:io a través de la plataforma.)

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({
    required this.barName,
    required this.session,
    required this.items,
    required this.grouped,
  });

  final String barName;
  final TableSessionEntity session;
  final List<OrderItemEntity> items;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReceiptHeader(
          barName: barName,
          tableNumber: session.tableNumber,
          // Sin apodo: es interno del mesero; la factura es para el cliente.
          apodo: null,
          openedAt: session.openedAt,
        ),
        const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
        if (grouped)
          ReceiptGrouped(items: items)
        else
          ReceiptChronological(items: items),
        const DashedDivider(padding: EdgeInsets.symmetric(vertical: 10)),
        ReceiptFooter(items: items, showThanks: true),
      ],
    );
  }
}
