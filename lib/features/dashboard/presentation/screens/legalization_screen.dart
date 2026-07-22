import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../../payments/domain/entities/payment_receipt_entity.dart';
import '../providers/dashboard_providers.dart';

/// Cashier legalization screen for transfer receipts.
///
/// ── Two tabs ──────────────────────────────────────────────────────────────────
///   • Pendientes: transfers captured by the waiter, awaiting cashier verification.
///   • Legalizadas: transfers already confirmed in the register.
///
/// ── Re-injection trigger ─────────────────────────────────────────────────────
/// Tapping "COBRADO EN CAJA" calls [LegalizationNotifier.legalizeTransfer].
/// The Isar stream fires → [enrichedWalletSummaryProvider] recomputes →
/// the waiter's Available Balance updates immediately across the app.
class LegalizationScreen extends ConsumerStatefulWidget {
  const LegalizationScreen({super.key});

  @override
  ConsumerState<LegalizationScreen> createState() => _LegalizationScreenState();
}

class _LegalizationScreenState extends ConsumerState<LegalizationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onLegalizar(PaymentReceiptEntity receipt) async {
    final failure = await ref
        .read(legalizationProvider.notifier)
        .legalizeTransfer(receipt.id);

    if (!mounted) return;

    if (failure != null) {
      AppToast.error(context, failure.message);
      return;
    }

    AppToast.success(
        context, 'Transferencia de ${receipt.amountPaid.toCop} legalizada.');
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = ref.watch(pendingTransfersProvider);
    final legalizedList = ref.watch(legalizedTransfersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Legalizar Transferencias', style: AppTextStyles.headlineSmall),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brand,
          labelColor: AppColors.brand,
          unselectedLabelColor:
              isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pendientes'),
                  if (pendingList.isNotEmpty) ...[
                    const SizedBox(width: AppDimensions.space8),
                    _CountBadge(
                      count: pendingList.length,
                      color: AppColors.statusOrange,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Legalizadas'),
                  if (legalizedList.isNotEmpty) ...[
                    const SizedBox(width: AppDimensions.space8),
                    _CountBadge(
                      count: legalizedList.length,
                      color: AppColors.statusGreen,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Pendientes ────────────────────────────────────────
          _TransferList(
            receipts: pendingList,
            isPending: true,
            onLegalizar: _onLegalizar,
            emptyLabel: 'Sin transferencias pendientes',
            emptySubtitle:
                'Todas las transferencias han sido verificadas en caja.',
            emptyIcon: Icons.verified_rounded,
            emptyColor: AppColors.statusGreen,
          ),

          // ── Tab 2: Legalizadas ───────────────────────────────────────
          _TransferList(
            receipts: legalizedList,
            isPending: false,
            onLegalizar: (_) {},
            emptyLabel: 'Sin transferencias legalizadas',
            emptySubtitle: 'Legaliza las transferencias pendientes para verlas aquí.',
            emptyIcon: Icons.smartphone_rounded,
            emptyColor: AppColors.statusBlue,
          ),
        ],
      ),
    );
  }
}

// ── Transfer list ─────────────────────────────────────────────────────────────

class _TransferList extends StatelessWidget {
  const _TransferList({
    required this.receipts,
    required this.isPending,
    required this.onLegalizar,
    required this.emptyLabel,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.emptyColor,
  });

  final List<PaymentReceiptEntity> receipts;
  final bool isPending;
  final void Function(PaymentReceiptEntity) onLegalizar;
  final String emptyLabel;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    if (receipts.isEmpty) {
      return _EmptyTabBody(
        label: emptyLabel,
        subtitle: emptySubtitle,
        icon: emptyIcon,
        color: emptyColor,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.space16,
      ),
      itemCount: receipts.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.space12),
      itemBuilder: (context, index) => _TransferReceiptCard(
        receipt: receipts[index],
        isPending: isPending,
        onLegalizar: () => onLegalizar(receipts[index]),
      ),
    );
  }
}

// ── Transfer receipt card ─────────────────────────────────────────────────────

class _TransferReceiptCard extends StatelessWidget {
  const _TransferReceiptCard({
    required this.receipt,
    required this.isPending,
    required this.onLegalizar,
  });

  final PaymentReceiptEntity receipt;
  final bool isPending;
  final VoidCallback onLegalizar;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isPending ? AppColors.statusOrange : AppColors.statusGreen;
    final method = receipt.transferMethod;
    final methodColor = method?.displayColor ?? AppColors.statusBlue;

    return ReceiptPaper(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Encabezado: plataforma + mesa + estado ──────────────
          Row(
            children: [
              if (method != null) ...[
                Icon(method.displayIcon, color: methodColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  method.displayLabel.toUpperCase(),
                  style: AppTextStyles.receiptSmall
                      .copyWith(color: methodColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  'Mesa ${receipt.tableSessionId}',
                  style: AppTextStyles.receiptSmall
                      .copyWith(color: AppColors.paperInkSoft),
                ),
              ),
              Text(
                isPending ? 'PENDIENTE' : 'LEGALIZADA',
                style: AppTextStyles.receiptSmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const DashedDivider(padding: EdgeInsets.symmetric(vertical: 8)),

          // ── Foto + monto ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (receipt.photoPath != null) ...[
                _PhotoThumbnail(path: receipt.photoPath!),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTO TRANSFERIDO',
                      style: AppTextStyles.receiptSmall
                          .copyWith(color: AppColors.paperInkSoft),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      receipt.amountPaid.toCop,
                      style: AppTextStyles.receiptTotal
                          .copyWith(fontSize: 20, color: AppColors.paperInk),
                    ),
                    if (receipt.tipAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Propina: ${receipt.tipAmount.toCop}',
                        style: AppTextStyles.receiptSmall
                            .copyWith(color: AppColors.primaryDark),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('d MMM yyyy • HH:mm', 'es_CO')
                          .format(receipt.paidAt),
                      style: AppTextStyles.receiptSmall
                          .copyWith(color: AppColors.paperInkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Código de verificación ───────────────────────────────
          if (receipt.verificationCode != null) ...[
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 8)),
            _VerificationCodeRow(code: receipt.verificationCode!),
          ],

          // ── COBRADO EN CAJA (solo pendientes) ────────────────────
          if (isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightMd,
              child: FilledButton.icon(
                onPressed: onLegalizar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusGreen,
                  foregroundColor: AppColors.onStatusGreen,
                  minimumSize:
                      Size(double.infinity, AppDimensions.buttonHeightMd),
                ),
                icon: const Icon(Icons.verified_rounded),
                label: Text(
                  'COBRADO EN CAJA',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.onStatusGreen),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Photo thumbnail ────────────────────────────────────────────────────────────

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullPhoto(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            cacheWidth: 160,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: AppColors.darkSurfaceVariant,
              child: const Icon(Icons.broken_image_rounded,
                  color: AppColors.darkDisabled),
            ),
            frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) return child;
              return Container(
                width: 80,
                height: 80,
                color: AppColors.darkSurfaceVariant,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.darkOnSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullPhoto(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: InteractiveViewer(
            child: Image.file(
              File(path),
              errorBuilder: (_, __, ___) => Container(
                width: 200,
                height: 200,
                color: AppColors.darkSurfaceVariant,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded,
                        color: AppColors.darkDisabled, size: 48),
                    SizedBox(height: 8),
                    Text('Foto no disponible',
                        style: TextStyle(color: AppColors.darkOnSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Verification code row ─────────────────────────────────────────────────────

class _VerificationCodeRow extends StatelessWidget {
  const _VerificationCodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.key_rounded, color: AppColors.primaryDark, size: 15),
        const SizedBox(width: 6),
        Text('Código:',
            style: AppTextStyles.receiptSmall.copyWith(color: AppColors.paperInkSoft)),
        const SizedBox(width: 6),
        Text(
          code,
          style: AppTextStyles.receiptBodyBold.copyWith(color: AppColors.paperInk),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            AppToast.info(context, 'Código $code copiado');
          },
          child: const Icon(Icons.copy_rounded,
              size: 16, color: AppColors.paperInkSoft),
        ),
      ],
    );
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.statusBadge.copyWith(color: color),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyTabBody extends StatelessWidget {
  const _EmptyTabBody({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color.withOpacity(0.3)),
            const SizedBox(height: AppDimensions.space16),
            Text(
              label,
              style: AppTextStyles.headlineSmall.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              subtitle,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
