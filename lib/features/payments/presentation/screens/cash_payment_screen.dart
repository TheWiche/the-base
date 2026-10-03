import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
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
    final subtotal = widget.args.billSubtotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pago en Efectivo',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.ink),
        ),
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
                color: AppColors.inkSecondary,
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
              style: AppTextStyles.monoLarge.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.paperSurface,
                prefixText: '\$ ',
                prefixStyle: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                hintText: '0',
                hintStyle: AppTextStyles.monoLarge.copyWith(
                  color: AppColors.inkSecondary.withValues(alpha: 0.3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  borderSide: const BorderSide(color: AppColors.paperBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  borderSide: const BorderSide(color: AppColors.paperBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
              height: AppDimensions.buttonHeightMd,
              child: FilledButton.icon(
                onPressed: (_isValid && !_isRecording) ? _confirmPayment : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                  ),
                ),
                icon: _isRecording
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'CONFIRMAR PAGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
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
      isGeneralAdvance: widget.args.isGeneralAdvance,
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
    AppToast.success(
      context,
      _changeGiven > 0
          ? 'Pago registrado. Vuelto: ${_changeGiven.toCop}'
          : 'Pago registrado: ${widget.args.billSubtotal.toCop}',
    );
    context.pop();
  }

  void _showError(Failure failure) => AppToast.error(context, failure.message);
}

// ── Bill total card ────────────────────────────────────────────────────────────

class _BillTotalCard extends StatelessWidget {
  const _BillTotalCard({required this.subtotal});

  final int subtotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.paperSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(color: AppColors.paperBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL A COBRAR',
            style: AppTextStyles.statusBadge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            subtotal.toCop,
            style: AppTextStyles.monoLarge.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 32,
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
    final isInsufficient = received > 0 && received < subtotal;
    final isExact = received == subtotal && received > 0;
    final hasChange = changeGiven > 0;

    final (statusColor, statusLabel, statusIcon) = isInsufficient
        ? (AppColors.statusRed, 'MONTO INSUFICIENTE', Icons.warning_rounded)
        : isExact
            ? (AppColors.statusGreen, 'PAGO EXACTO', Icons.check_circle_rounded)
            : hasChange
                ? (AppColors.primary, 'VUELTO', Icons.currency_exchange_rounded)
                : (AppColors.inkSecondary.withValues(alpha: 0.4),
                   'VUELTO', Icons.currency_exchange_rounded);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        border: Border.all(
          color: statusColor.withValues(alpha: received > 0 ? 0.5 : 0.2),
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
                  style: AppTextStyles.statusBadge.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
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
                    style: AppTextStyles.monoLarge.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
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
    final s = number.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    final formatted = buf.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
