import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../providers/payment_providers.dart';

/// Cash payment screen — shows bill total, money-received input, and
/// live change (vuelto) calculation.
///
/// Receives [PaymentNavigationArgs] via GoRouter [extra].
/// On "CONFIRMAR PAGO": calls [RecordPaymentUseCase] and navigates to the
/// table order screen, clearing the billing selection.
class CashPaymentScreen extends ConsumerStatefulWidget {
  const CashPaymentScreen({super.key, required this.args});

  final PaymentNavigationArgs args;

  @override
  ConsumerState<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends ConsumerState<CashPaymentScreen> {
  final _receivedController = TextEditingController();
  int _receivedAmount = 0;
  bool _isRecording = false;

  int get _changeGiven => _receivedAmount > widget.args.billSubtotal
      ? _receivedAmount - widget.args.billSubtotal
      : 0;

  bool get _isValid => _receivedAmount >= widget.args.billSubtotal;

  @override
  void dispose() {
    _receivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = widget.args.billSubtotal;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pago en Efectivo', style: AppTextStyles.headlineSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bill total card ────────────────────────────────────────
            _BillTotalCard(subtotal: subtotal),
            const SizedBox(height: AppDimensions.space24),

            // ── Received amount input ──────────────────────────────────
            Text(
              'MONTO RECIBIDO',
              style: AppTextStyles.statusBadge.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            TextFormField(
              controller: _receivedController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorFormatter(),
              ],
              style: AppTextStyles.displayMedium,
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: AppTextStyles.headlineMedium.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
                hintText: '0',
                hintStyle: AppTextStyles.displayMedium.copyWith(
                  color: isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
                ),
              ),
              onChanged: (raw) {
                final digits = raw.replaceAll('.', '');
                setState(() {
                  _receivedAmount = int.tryParse(digits) ?? 0;
                });
              },
            ),
            const SizedBox(height: AppDimensions.space32),

            // ── Change (vuelto) display ────────────────────────────────
            _ChangeDisplay(
              received: _receivedAmount,
              subtotal: subtotal,
              changeGiven: _changeGiven,
            ),
            const SizedBox(height: AppDimensions.space40),

            // ── Confirm button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLg,
              child: FilledButton.icon(
                onPressed: (_isValid && !_isRecording) ? _confirmPayment : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusGreen,
                  foregroundColor: Colors.black,
                ),
                icon: _isRecording
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  'CONFIRMAR PAGO',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment() async {
    if (!_isValid || _isRecording) return;
    setState(() => _isRecording = true);

    final params = RecordPaymentParams(
      tableSessionId: widget.args.sessionId,
      selectedItemIds: widget.args.selectedItemIds,
      selectedQuantities: widget.args.selectedQuantities,
      amountPaid: _receivedAmount,
      billSubtotal: widget.args.billSubtotal,
      paymentMethod: PaymentMethod.cash,
    );

    final failure =
        await ref.read(paymentNotifierProvider.notifier).recordPayment(params);

    if (!mounted) return;
    setState(() => _isRecording = false);

    if (failure != null) {
      _showError(failure);
      return;
    }

    if (!mounted) return;
    await _showPaymentConfirmation();
    if (mounted) context.pop();
  }

  Future<void> _showPaymentConfirmation() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentConfirmationDialog(
        method: 'Efectivo',
        amountPaid: _receivedAmount,
        changeGiven: _changeGiven,
        subtotal: widget.args.billSubtotal,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showError(Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure.message),
        backgroundColor: AppColors.statusRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Bill total card ────────────────────────────────────────────────────────────

class _BillTotalCard extends StatelessWidget {
  const _BillTotalCard({required this.subtotal});

  final int subtotal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL A COBRAR',
            style: AppTextStyles.statusBadge.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            subtotal.toCop,
            style: AppTextStyles.displayLarge.copyWith(
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Change display ─────────────────────────────────────────────────────────────

class _ChangeDisplay extends StatelessWidget {
  const _ChangeDisplay({
    required this.received,
    required this.subtotal,
    required this.changeGiven,
  });

  final int received;
  final int subtotal;
  final int changeGiven;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInsufficient = received > 0 && received < subtotal;
    final isExact = received == subtotal && received > 0;
    final hasChange = changeGiven > 0;

    final (statusColor, statusLabel, statusIcon) = isInsufficient
        ? (AppColors.statusRed, 'MONTO INSUFICIENTE', Icons.warning_rounded)
        : isExact
            ? (AppColors.statusGreen, 'PAGO EXACTO', Icons.check_circle_rounded)
            : hasChange
                ? (AppColors.brand, 'VUELTO', Icons.currency_exchange_rounded)
                : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled,
                   'VUELTO', Icons.currency_exchange_rounded);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: statusColor.withOpacity(received > 0 ? 0.5 : 0.2),
          width: received > 0 ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: AppDimensions.iconLg),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: AppTextStyles.statusBadge.copyWith(color: statusColor),
                ),
                const SizedBox(height: AppDimensions.space4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    isInsufficient
                        ? (subtotal - received).toAbsCop
                        : changeGiven > 0
                            ? changeGiven.toCop
                            : '\$ 0',
                    key: ValueKey(changeGiven),
                    style: AppTextStyles.displaySmall.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
                if (isInsufficient)
                  Text(
                    'Faltan ${(subtotal - received).toCop} para completar la cuenta.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.statusRed,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment confirmation dialog ────────────────────────────────────────────────

class _PaymentConfirmationDialog extends StatelessWidget {
  const _PaymentConfirmationDialog({
    required this.method,
    required this.amountPaid,
    required this.changeGiven,
    required this.subtotal,
    required this.onClose,
    this.verificationCode,
    this.transferMethodLabel,
  });

  final String method;
  final int amountPaid;
  final int changeGiven;
  final int subtotal;
  final String? verificationCode;
  final String? transferMethodLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      icon: const Icon(
        Icons.check_circle_rounded,
        color: AppColors.statusGreen,
        size: 48,
      ),
      title: Text(
        'Pago Registrado',
        style: AppTextStyles.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ConfirmRow(
            label: 'Método',
            value: transferMethodLabel != null
                ? '$method · $transferMethodLabel'
                : method,
            color: AppColors.statusGreen,
            isDark: isDark,
          ),
          _ConfirmRow(
            label: 'Total cobrado',
            value: subtotal.toCop,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            isDark: isDark,
          ),
          if (amountPaid != subtotal)
            _ConfirmRow(
              label: 'Recibido',
              value: amountPaid.toCop,
              color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
              isDark: isDark,
            ),
          if (changeGiven > 0)
            _ConfirmRow(
              label: 'Vuelto',
              value: changeGiven.toCop,
              color: AppColors.brand,
              isDark: isDark,
            ),
          if (verificationCode != null)
            _ConfirmRow(
              label: 'Código verificación',
              value: verificationCode!,
              color: AppColors.statusBlue,
              isDark: isDark,
            ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton.icon(
          onPressed: onClose,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.statusGreen,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('VOLVER AL PEDIDO'),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.lightOnSurfaceVariant,
            ),
          ),
          Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Thousands separator formatter ──────────────────────────────────────────────

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = _format(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
