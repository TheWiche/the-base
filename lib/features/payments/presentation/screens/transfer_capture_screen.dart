import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../utils/photo_rotation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../providers/payment_providers.dart';

/// Transfer payment screen — three sequential phases:
///
///   1. **[_Phase.initial]** — Instruction card + "TOMAR FOTO" button.
///      [ImagePicker.pickImage] opens the native camera with JPEG compression
///      (quality 80 %, max 1200 px) to minimize storage impact.
///
///   2. **[_Phase.preview]** — Shows the captured image full-screen.
///      "Retomar" discards and reopens the camera.
///      "Continuar" advances to the details sheet.
///
///   3. **[_Phase.recording]** — Loading overlay while the atomic Isar write +
///      file copy to Bonanza_Transferencias executes.
///
/// On success, navigates to `/tables/:sessionId/orders` so the waiter sees
/// the updated paid-item states.
class TransferCaptureScreen extends ConsumerStatefulWidget {
  const TransferCaptureScreen({super.key, required this.args});

  final PaymentNavigationArgs args;

  @override
  ConsumerState<TransferCaptureScreen> createState() =>
      _TransferCaptureScreenState();
}

enum _Phase { initial, preview, recording }

class _TransferCaptureScreenState
    extends ConsumerState<TransferCaptureScreen> {
  _Phase _phase = _Phase.initial;
  XFile? _capturedPhoto;
  int _rotationTurns = 0;

  // ── Photo capture / pick ─────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    await _pickPhoto(ImageSource.camera);
  }

  Future<void> _openGallery() async {
    await _pickPhoto(ImageSource.gallery);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: source,
        imageQuality: 80,     // JPEG compression — reduces ~3 MB → ~400 KB
        maxWidth: 1200,
        maxHeight: 1600,
        preferredCameraDevice: CameraDevice.rear,
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'No se pudo acceder a la cámara: $e'
                : 'No se pudo acceder a la galería: $e',
          ),
          backgroundColor: AppColors.statusRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    if (file == null) return; // user cancelled

    setState(() {
      _capturedPhoto = file;
      _phase = _Phase.preview;
    });
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
      _phase = _Phase.initial;
      _rotationTurns = 0;
    });
  }

  void _rotatePhoto() {
    setState(() => _rotationTurns = (_rotationTurns + 1) % 4);
  }

  // ── Transfer details sheet ───────────────────────────────────────────────────

  Future<void> _showDetailsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransferDetailsSheet(
        billSubtotal: widget.args.billSubtotal,
        onConfirm: _recordPayment,
      ),
    );
  }

  Future<void> _recordPayment({
    required TransferMethod method,
    required int tipAmount,
  }) async {
    if (_capturedPhoto == null) return;
    setState(() => _phase = _Phase.recording);

    final effectivePath =
        await applyPhotoRotation(_capturedPhoto!.path, _rotationTurns);
    final totalPaid = widget.args.billSubtotal + tipAmount;

    final params = RecordPaymentParams(
      tableSessionId: widget.args.sessionId,
      selectedItemIds: widget.args.selectedItemIds,
      selectedQuantities: widget.args.selectedQuantities,
      amountPaid: totalPaid,
      billSubtotal: widget.args.billSubtotal,
      paymentMethod: PaymentMethod.transfer,
      transferMethod: method,
      photoSourcePath: effectivePath,
      tipAmount: tipAmount,
    );

    final failure =
        await ref.read(paymentNotifierProvider.notifier).recordPayment(params);

    if (!mounted) return;
    setState(() => _phase = _Phase.preview);

    if (failure != null) {
      _showError(failure);
      return;
    }

    if (!mounted) return;
    await _showPaymentConfirmation(
      method: method,
      totalPaid: totalPaid,
      tipAmount: tipAmount,
    );
    if (mounted) context.pop();
  }

  Future<void> _showPaymentConfirmation({
    required TransferMethod method,
    required int totalPaid,
    required int tipAmount,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TransferConfirmationDialog(
        transferMethodLabel: method.displayLabel,
        totalPaid: totalPaid,
        billSubtotal: widget.args.billSubtotal,
        tipAmount: tipAmount,
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _phase == _Phase.preview ? Colors.black : null,
      appBar: AppBar(
        backgroundColor:
            _phase == _Phase.preview ? Colors.black : null,
        foregroundColor:
            _phase == _Phase.preview ? Colors.white : null,
        title: Text(
          'Comprobante de Transferencia',
          style: AppTextStyles.headlineSmall.copyWith(
            color: _phase == _Phase.preview ? Colors.white : null,
          ),
        ),
      ),
      body: switch (_phase) {
        _Phase.initial => _InitialBody(
            billSubtotal: widget.args.billSubtotal,
            onTakePhoto: _openCamera,
            onPickFromGallery: _openGallery,
          ),
        _Phase.preview => _PreviewBody(
            photo: _capturedPhoto!,
            billSubtotal: widget.args.billSubtotal,
            rotationTurns: _rotationTurns,
            onRotate: _rotatePhoto,
            onRetake: _retakePhoto,
            onContinue: _showDetailsSheet,
          ),
        _Phase.recording => const _RecordingOverlay(),
      },
    );
  }
}

// ── Initial phase ─────────────────────────────────────────────────────────────

class _InitialBody extends StatelessWidget {
  const _InitialBody({
    required this.billSubtotal,
    required this.onTakePhoto,
    required this.onPickFromGallery,
  });

  final int billSubtotal;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFromGallery;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill amount reference
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space20),
            decoration: BoxDecoration(
              color: AppColors.statusBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: AppColors.statusBlue.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONTO A TRANSFERIR',
                  style: AppTextStyles.statusBadge.copyWith(
                    color: AppColors.statusBlue,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  billSubtotal.toCop,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space32),

          // Instructions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.brand,
                size: AppDimensions.iconSm,
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  'Pide al cliente que muestre el comprobante de transferencia '
                  'y toma una foto clara del pantallazos.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.folder_rounded,
                color: AppColors.brand,
                size: AppDimensions.iconSm,
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  'La foto se guardará en la carpeta '
                  '"Bonanza_Transferencias" de tu dispositivo.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Capture buttons row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: AppDimensions.buttonHeightLg,
                  child: FilledButton.icon(
                    onPressed: onTakePhoto,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.statusBlue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text(
                      'TOMAR FOTO',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeightLg,
                  child: OutlinedButton.icon(
                    onPressed: onPickFromGallery,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.lightOnSurface,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkOutline
                            : AppColors.lightOutline,
                        width: 1.5,
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 20),
                    label: Text(
                      'GALERÍA',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space24),
        ],
      ),
    );
  }
}

// ── Preview phase ─────────────────────────────────────────────────────────────

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.photo,
    required this.billSubtotal,
    required this.rotationTurns,
    required this.onRotate,
    required this.onRetake,
    required this.onContinue,
  });

  final XFile photo;
  final int billSubtotal;
  final int rotationTurns;
  final VoidCallback onRotate;
  final VoidCallback onRetake;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-screen photo ──────────────────────────────────────────
        InteractiveViewer(
          child: RotatedBox(
            quarterTurns: rotationTurns,
            child: Image.file(
              File(photo.path),
              fit: BoxFit.contain,
            ),
          ),
        ),

        // ── Rotate button (top-right) ──────────────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
              tooltip: 'Girar 90°',
              onPressed: onRotate,
            ),
          ),
        ),

        // ── Bottom overlay with actions ────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.space32,
              AppDimensions.pagePaddingH,
              AppDimensions.space32,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amount reminder
                  Text(
                    'Comprobante por ${billSubtotal.toCop}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Action row
                  Row(
                    children: [
                      // Retake
                      Expanded(
                        child: SizedBox(
                          height: AppDimensions.buttonHeightMd,
                          child: OutlinedButton.icon(
                            onPressed: onRetake,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white54,
                                width: 2,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(
                              'CAMBIAR',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),

                      // Continue
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: AppDimensions.buttonHeightMd,
                          child: FilledButton.icon(
                            onPressed: onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.statusGreen,
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              'CONTINUAR',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Recording overlay ─────────────────────────────────────────────────────────

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppDimensions.space16),
          Text('Registrando pago…'),
        ],
      ),
    );
  }
}

// ── Transfer details sheet ─────────────────────────────────────────────────────

class _TransferDetailsSheet extends StatefulWidget {
  const _TransferDetailsSheet({
    required this.billSubtotal,
    required this.onConfirm,
  });

  final int billSubtotal;
  final Future<void> Function({
    required TransferMethod method,
    required int tipAmount,
  }) onConfirm;

  @override
  State<_TransferDetailsSheet> createState() => _TransferDetailsSheetState();
}

class _TransferDetailsSheetState extends State<_TransferDetailsSheet> {
  TransferMethod? _selectedMethod;
  final _tipController = TextEditingController();
  int _tipAmount = 0;
  bool _isConfirming = false;

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canConfirm = _selectedMethod != null && !_isConfirming;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePaddingH,
          AppDimensions.space24,
          AppDimensions.pagePaddingH,
          AppDimensions.space32,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkOutline
                        : AppColors.lightOutline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Detalles de la transferencia',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: AppDimensions.space20),

              // ── Platform picker ────────────────────────────────────
              Text(
                'PLATAFORMA',
                style: AppTextStyles.statusBadge.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: TransferMethod.values.map((method) {
                  final isSelected = _selectedMethod == method;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMethod = method);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(
                          right: method != TransferMethod.values.last
                              ? AppDimensions.space8
                              : 0,
                        ),
                        height: AppDimensions.tapTargetLg,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? method.displayColor.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? method.displayColor
                                : (isDark
                                    ? AppColors.darkOutline
                                    : AppColors.lightOutline),
                            width: isSelected ? 2.0 : 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              method.displayIcon,
                              color: isSelected
                                  ? method.displayColor
                                  : (isDark
                                      ? AppColors.darkDisabled
                                      : AppColors.lightDisabled),
                              size: AppDimensions.iconSm,
                            ),
                            const SizedBox(height: AppDimensions.space4),
                            Text(
                              method.displayLabel,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isSelected
                                    ? method.displayColor
                                    : (isDark
                                        ? AppColors.darkDisabled
                                        : AppColors.lightDisabled),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimensions.space24),

              // ── Optional tip ───────────────────────────────────────
              Text(
                'PROPINA (opcional)',
                style: AppTextStyles.statusBadge.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              TextFormField(
                controller: _tipController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _TipSeparatorFormatter(),
                ],
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0  —  sin propina',
                ),
                onChanged: (raw) {
                  final digits = raw.replaceAll('.', '');
                  setState(() {
                    _tipAmount = int.tryParse(digits) ?? 0;
                  });
                },
              ),

              const SizedBox(height: AppDimensions.space32),

              // ── Summary row ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total transferido',
                      style: AppTextStyles.bodyLarge,
                    ),
                    Text(
                      (widget.billSubtotal + _tipAmount).toCop,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.statusGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space20),

              // ── Confirm button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLg,
                child: FilledButton.icon(
                  onPressed: canConfirm
                      ? () async {
                          if (_selectedMethod == null) return;
                          setState(() => _isConfirming = true);
                          Navigator.of(context).pop();
                          await widget.onConfirm(
                            method: _selectedMethod!,
                            tipAmount: _tipAmount,
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusBlue,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'REGISTRAR PAGO',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Transfer confirmation dialog ───────────────────────────────────────────────

class _TransferConfirmationDialog extends StatelessWidget {
  const _TransferConfirmationDialog({
    required this.transferMethodLabel,
    required this.totalPaid,
    required this.billSubtotal,
    required this.tipAmount,
    required this.onClose,
  });

  final String transferMethodLabel;
  final int totalPaid;
  final int billSubtotal;
  final int tipAmount;
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
        'Transferencia Registrada',
        style: AppTextStyles.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(
            label: 'Método',
            value: transferMethodLabel,
            color: AppColors.statusBlue,
            isDark: isDark,
          ),
          _Row(
            label: 'Total cobrado',
            value: billSubtotal.toCop,
            color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
            isDark: isDark,
          ),
          if (tipAmount > 0)
            _Row(
              label: 'Propina',
              value: tipAmount.toCop,
              color: AppColors.brand,
              isDark: isDark,
            ),
          _Row(
            label: 'Total transferido',
            value: totalPaid.toCop,
            color: AppColors.statusGreen,
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.space8),
          Container(
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.statusOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.statusOrange.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.statusOrange, size: 16),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: Text(
                    'Recuerda legalizar la transferencia en caja.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.statusOrange,
                    ),
                  ),
                ),
              ],
            ),
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

class _Row extends StatelessWidget {
  const _Row({
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

// ── Tip separator formatter ────────────────────────────────────────────────────

class _TipSeparatorFormatter extends TextInputFormatter {
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
