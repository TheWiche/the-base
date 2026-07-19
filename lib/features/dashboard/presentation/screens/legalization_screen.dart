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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isPending ? AppColors.statusOrange : AppColors.statusGreen;
    final method = receipt.transferMethod;
    final methodColor = method?.displayColor ?? AppColors.statusBlue;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header strip ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: Row(
              children: [
                // Platform badge
                if (method != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: methodColor.withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(
                          color: methodColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(method.displayIcon,
                            color: methodColor,
                            size: AppDimensions.iconSm),
                        const SizedBox(width: AppDimensions.space4),
                        Text(
                          method.displayLabel.toUpperCase(),
                          style: AppTextStyles.statusBadge
                              .copyWith(color: methodColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                ],

                Expanded(
                  child: Text(
                    'Mesa ${receipt.tableSessionId}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ),

                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.badgePaddingH,
                    vertical: AppDimensions.badgePaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    isPending ? 'PENDIENTE' : 'LEGALIZADA',
                    style:
                        AppTextStyles.statusBadge.copyWith(color: accentColor),
                  ),
                ),
              ],
            ),
          ),

          // ── Photo thumbnail + amounts ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo preview
                if (receipt.photoPath != null)
                  _PhotoThumbnail(path: receipt.photoPath!),

                if (receipt.photoPath != null)
                  const SizedBox(width: AppDimensions.space16),

                // Amount + tip + timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTO TRANSFERIDO',
                        style: AppTextStyles.statusBadge.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        receipt.amountPaid.toCop,
                        style: AppTextStyles.displaySmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.lightOnSurface,
                        ),
                      ),

                      if (receipt.tipAmount > 0) ...[
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          'Propina: ${receipt.tipAmount.toCop}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.brand,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        DateFormat('d MMM yyyy • HH:mm', 'es_CO')
                            .format(receipt.paidAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Verification code ─────────────────────────────────────
          if (receipt.verificationCode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                0,
                AppDimensions.space16,
                AppDimensions.space12,
              ),
              child: _VerificationCodeRow(code: receipt.verificationCode!),
            ),

          // ── COBRADO EN CAJA button (pending only) ─────────────────
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                0,
                AppDimensions.space16,
                AppDimensions.space16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightMd,
                child: FilledButton.icon(
                  onPressed: onLegalizar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusGreen,
                    foregroundColor: AppColors.onStatusGreen,
                    // Override global theme minimumSize (Size.fromHeight → ∞)
                    minimumSize: Size(
                      double.infinity,
                      AppDimensions.buttonHeightMd,
                    ),
                  ),
                  icon: const Icon(Icons.verified_rounded),
                  label: Text(
                    'COBRADO EN CAJA',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.onStatusGreen),
                  ),
                ),
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.brand.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.key_rounded,
              color: AppColors.brand, size: AppDimensions.iconSm),
          const SizedBox(width: AppDimensions.space8),
          Text(
            'Código: ',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),
          ),
          Text(
            code,
            style: AppTextStyles.mono.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              AppToast.info(context, 'Código $code copiado');
            },
            child: Icon(Icons.copy_rounded,
                size: AppDimensions.iconSm,
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant),
          ),
        ],
      ),
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
