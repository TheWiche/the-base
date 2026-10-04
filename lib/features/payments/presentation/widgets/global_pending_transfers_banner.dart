import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/payment_receipt_entity.dart';

/// Banner global persistente de advertencia para transferencias sin cobrar en caja.
///
/// Aparece en la parte superior de todas las pantallas principales mientras
/// existan comprobantes pendientes de legalización. Alto contraste (naranja/ámbar).
/// Al tocarlo en cualquier pantalla, despliega un BottomSheet modal en 1 clic
/// con la lista de transferencias y el botón directo "COBRADO EN CAJA".
class GlobalPendingTransfersBanner extends ConsumerWidget {
  const GlobalPendingTransfersBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingList = ref.watch(pendingTransfersProvider);
    if (pendingList.isEmpty) return const SizedBox.shrink();

    final totalAmount =
        pendingList.fold<int>(0, (sum, r) => sum + r.amountPaid);
    final count = pendingList.length;

    // Barra de estado de alta visibilidad para exteriores (luz solar directa)
    return Material(
      color: const Color(0xFFE65100), // Ámbar quemado de alto impacto visual
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/legalizacion');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚡ $count ${count == 1 ? "transferencia" : "transferencias"} sin mostrar en caja (${totalAmount.toCop})',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'IR',
                        style: AppTextStyles.statusBadge.copyWith(
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFE65100),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── BottomSheet modal de 1 clic ────────────────────────────────────────────────

class _PendingTransfersSheet extends ConsumerWidget {
  const _PendingTransfersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingList = ref.watch(pendingTransfersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAmount =
        pendingList.fold<int>(0, (sum, r) => sum + r.amountPaid);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.space16,
        AppDimensions.pagePaddingH,
        AppDimensions.pagePaddingH + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asa superior
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkOutline
                          : AppColors.lightOutline)
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFE65100),
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transferencias por Legalizar',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pendingList.isEmpty
                            ? 'Todo al día con caja'
                            : '${pendingList.length} pendientes · Total: ${totalAmount.toCop}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            // Contenido
            if (pendingList.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.statusGreen,
                        size: 54,
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        '¡Todas las transferencias están legalizadas!',
                        style: AppTextStyles.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No tienes dinero pendiente por cobrar en caja.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pendingList.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.space12),
                  itemBuilder: (context, index) {
                    final receipt = pendingList[index];
                    return _PendingReceiptTile(
                      key: ValueKey(receipt.id),
                      receipt: receipt,
                      onLegalize: () async {
                        HapticFeedback.mediumImpact();
                        final failure = await ref
                            .read(legalizationProvider.notifier)
                            .legalizeTransfer(receipt.id);
                        if (!context.mounted) return;
                        if (failure != null) {
                          AppToast.error(context, failure.message);
                        } else {
                          AppToast.success(
                            context,
                            'Transferencia de ${receipt.amountPaid.toCop} legalizada en caja.',
                          );
                          // Si ya no quedan más, cerrar el modal suavemente
                          if (pendingList.length <= 1) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.space8),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta individual de transferencia en el BottomSheet ─────────────────────

class _PendingReceiptTile extends StatelessWidget {
  const _PendingReceiptTile({
    super.key,
    required this.receipt,
    required this.onLegalize,
  });

  final PaymentReceiptEntity receipt;
  final VoidCallback onLegalize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final method = receipt.transferMethod;
    final methodColor = method?.displayColor ?? AppColors.statusBlue;

    final tableName = receipt.tableSessionId == 0
        ? 'Cobro Suelto / Sin Mesa'
        : 'Mesa ${receipt.tableSessionId}';

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: const Color(0xFFE65100).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (method != null) ...[
                Icon(method.displayIcon, color: methodColor, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    method.displayLabel.toUpperCase(),
                    style: AppTextStyles.receiptSmall.copyWith(
                      color: methodColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: Text(
                  tableName,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(receipt.paidAt),
                style: AppTextStyles.mono.copyWith(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Miniatura de la foto con tap para ver grande
              if (receipt.photoPath != null) ...[
                GestureDetector(
                  onTap: () => _openImageDialog(context, receipt.photoPath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(
                          File(receipt.photoPath!),
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 54,
                            height: 54,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: const Icon(Icons.broken_image_rounded,
                                size: 24),
                          ),
                        ),
                        Container(
                          width: 54,
                          height: 54,
                          color: Colors.black26,
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        receipt.amountPaid.toCop,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (receipt.tipAmount > 0)
                      Text(
                        '+ ${receipt.tipAmount.toCop} propina',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.statusGreen,
                        ),
                      ),
                    if (receipt.note != null && receipt.note!.isNotEmpty)
                      Text(
                        receipt.note!,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              // Botón directo "COBRADO EN CAJA"
              FilledButton.icon(
                onPressed: onLegalize,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Cobrado en Caja'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openImageDialog(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
