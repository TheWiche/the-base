import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../providers/payment_providers.dart';
import '../utils/photo_rotation.dart';

/// Pantalla de Pago Mixto (Efectivo + Transferencia simultáneos).
class MixedPaymentScreen extends ConsumerStatefulWidget {
  const MixedPaymentScreen({super.key, required this.args});

  final PaymentNavigationArgs args;

  @override
  ConsumerState<MixedPaymentScreen> createState() => _MixedPaymentScreenState();
}

class _MixedPaymentScreenState extends ConsumerState<MixedPaymentScreen> {
  final _cashController = TextEditingController();
  final _transferController = TextEditingController();

  int _cashAmount = 0;
  int _transferAmount = 0;
  TransferMethod _transferMethod = TransferMethod.nequi;

  XFile? _transferPhoto;
  int _rotationTurns = 0;
  bool _isRecording = false;

  int get _totalTarget => widget.args.billSubtotal;
  int get _sum => _cashAmount + _transferAmount;
  bool get _isValid =>
      _cashAmount > 0 &&
      _transferAmount > 0 &&
      _sum >= _totalTarget &&
      _transferPhoto != null;

  int get _changeGiven => _sum > _totalTarget ? _sum - _totalTarget : 0;

  @override
  void initState() {
    super.initState();
    // Sugerencia inicial: dividir equitativamente o 0 / 0
  }

  @override
  void dispose() {
    _cashController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1600,
        preferredCameraDevice: CameraDevice.rear,
      );
    } on Exception catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        source == ImageSource.camera
            ? 'No se pudo acceder a la cámara: $e'
            : 'No se pudo acceder a la galería: $e',
      );
      return;
    }

    if (!mounted || file == null) return;
    setState(() {
      _transferPhoto = file;
      _rotationTurns = 0;
    });
  }

  void _rotatePhoto() =>
      setState(() => _rotationTurns = (_rotationTurns + 1) % 4);

  void _autoCompleteTransfer() {
    final remaining = (_totalTarget - _cashAmount).clamp(0, _totalTarget);
    _transferAmount = remaining;
    _transferController.text = _formatNumber(remaining);
    setState(() {});
  }

  void _autoCompleteCash() {
    final remaining = (_totalTarget - _transferAmount).clamp(0, _totalTarget);
    _cashAmount = remaining;
    _cashController.text = _formatNumber(remaining);
    setState(() {});
  }

  String _formatNumber(int val) {
    if (val == 0) return '0';
    final str = val.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Future<void> _confirmPayment() async {
    if (!_isValid || _isRecording) return;
    setState(() => _isRecording = true);

    final effectivePath =
        await applyPhotoRotation(_transferPhoto!.path, _rotationTurns);

    final params = RecordPaymentParams(
      tableSessionId: widget.args.sessionId,
      selectedItemIds: widget.args.selectedItemIds,
      selectedQuantities: widget.args.selectedQuantities,
      amountPaid: _sum,
      billSubtotal: _totalTarget,
      paymentMethod: PaymentMethod.transfer, // dummy base
      isMixed: true,
      cashAmount: _cashAmount,
      transferAmount: _transferAmount,
      mixedTransferMethod: _transferMethod,
      mixedPhotoSourcePath: effectivePath,
      isGeneralAdvance: widget.args.isGeneralAdvance,
    );

    final failure =
        await ref.read(paymentNotifierProvider.notifier).recordPayment(params);

    if (!mounted) return;
    setState(() => _isRecording = false);

    if (failure != null) {
      AppToast.error(context, failure.message);
      return;
    }

    AppToast.success(
      context,
      'Cobro mixto registrado: ${_cashAmount.toCop} efec + ${_transferAmount.toCop} trans',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pago Mixto', style: AppTextStyles.headlineSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Resumen de cuenta a cobrar ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.args.isGeneralAdvance
                        ? 'MONTO A ABONAR'
                        : 'TOTAL A COBRAR',
                    style: AppTextStyles.statusBadge.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(_totalTarget.toCop, style: AppTextStyles.displayLarge),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // ── Campo Efectivo ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_rounded,
                        color: AppColors.statusGreen, size: 20),
                    const SizedBox(width: 8),
                    Text('1. MONTO EN EFECTIVO',
                        style: AppTextStyles.labelLarge),
                  ],
                ),
                TextButton(
                  onPressed: _autoCompleteCash,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Restante'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              style: AppTextStyles.headlineMedium,
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: '0',
                filled: true,
                fillColor: AppColors.statusGreen.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide:
                      BorderSide(color: AppColors.statusGreen.withOpacity(0.4)),
                ),
              ),
              onChanged: (raw) {
                final digits = raw.replaceAll('.', '');
                setState(() {
                  _cashAmount = int.tryParse(digits) ?? 0;
                });
              },
            ),
            const SizedBox(height: AppDimensions.space20),

            // ── Campo Transferencia ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smartphone_rounded,
                        color: AppColors.statusBlue, size: 20),
                    const SizedBox(width: 8),
                    Text('2. MONTO EN TRANSFERENCIA',
                        style: AppTextStyles.labelLarge),
                  ],
                ),
                TextButton(
                  onPressed: _autoCompleteTransfer,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Restante'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _transferController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              style: AppTextStyles.headlineMedium,
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: '0',
                filled: true,
                fillColor: AppColors.statusBlue.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide:
                      BorderSide(color: AppColors.statusBlue.withOpacity(0.4)),
                ),
              ),
              onChanged: (raw) {
                final digits = raw.replaceAll('.', '');
                setState(() {
                  _transferAmount = int.tryParse(digits) ?? 0;
                });
              },
            ),
            const SizedBox(height: AppDimensions.space12),

            // ── Plataforma de transferencia ─────────────────────────────
            Wrap(
              spacing: 8,
              children: [
                for (final method in TransferMethod.values)
                  ChoiceChip(
                    label: Text(method.displayLabel),
                    selected: _transferMethod == method,
                    selectedColor: method.displayColor.withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected) setState(() => _transferMethod = method);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            // ── Comprobante de transferencia ─────────────────────────────
            Text('FOTO DEL COMPROBANTE', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            if (_transferPhoto == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Cámara'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.statusGreen),
                  color: AppColors.statusGreen.withOpacity(0.06),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: RotatedBox(
                        quarterTurns: _rotationTurns,
                        child: Image.file(
                          File(_transferPhoto!.path),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Comprobante adjunto',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right_rounded),
                      onPressed: _rotatePhoto,
                      tooltip: 'Rotar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      tooltip: 'Cambiar',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppDimensions.space20),

            // ── Vuelto o faltante ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _sum >= _totalTarget
                    ? AppColors.statusGreen.withOpacity(0.12)
                    : AppColors.statusOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _sum >= _totalTarget
                        ? (_changeGiven > 0 ? 'Vuelto en efectivo:' : 'Cubierto al 100%')
                        : 'Faltan para completar:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    _sum >= _totalTarget
                        ? (_changeGiven > 0 ? _changeGiven.toCop : 'OK')
                        : (_totalTarget - _sum).toCop,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: _sum >= _totalTarget
                          ? AppColors.statusGreen
                          : AppColors.statusOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // ── Botón confirmar ──────────────────────────────────────────
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
                label: const Text('CONFIRMAR PAGO MIXTO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll('.', '');
    final val = int.tryParse(digits);
    if (val == null) return oldValue;

    final str = digits;
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
