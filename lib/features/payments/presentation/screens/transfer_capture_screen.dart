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

/// Cobro por transferencia — flujo mínimo (2 taps):
///
///   1. Foto del comprobante (cámara o galería).
///   2. Preview con chips de plataforma (Nequi preseleccionado) →
///      REGISTRAR PAGO directo. Sin hoja de detalles, sin propina.
///
/// Éxito → toast + pop (Cobrar hace su auto-pop si quedó todo pagado).
class TransferCaptureScreen extends ConsumerStatefulWidget {
  const TransferCaptureScreen({super.key, required this.args});

  final PaymentNavigationArgs args;

  @override
  ConsumerState<TransferCaptureScreen> createState() =>
      _TransferCaptureScreenState();
}

enum _Phase { initial, preview, recording }

class _TransferCaptureScreenState extends ConsumerState<TransferCaptureScreen> {
  _Phase _phase = _Phase.initial;
  XFile? _capturedPhoto;
  int _rotationTurns = 0;
  TransferMethod _method = TransferMethod.values.first; // Nequi por defecto

  // ── Photo capture / pick ─────────────────────────────────────────────────────

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

  void _rotatePhoto() =>
      setState(() => _rotationTurns = (_rotationTurns + 1) % 4);

  // ── Record ───────────────────────────────────────────────────────────────────

  Future<void> _recordPayment() async {
    if (_capturedPhoto == null) return;
    setState(() => _phase = _Phase.recording);

    final effectivePath =
        await applyPhotoRotation(_capturedPhoto!.path, _rotationTurns);

    final params = RecordPaymentParams(
      tableSessionId: widget.args.sessionId,
      selectedItemIds: widget.args.selectedItemIds,
      selectedQuantities: widget.args.selectedQuantities,
      amountPaid: widget.args.billSubtotal,
      billSubtotal: widget.args.billSubtotal,
      paymentMethod: PaymentMethod.transfer,
      transferMethod: _method,
      photoSourcePath: effectivePath,
    );

    final failure =
        await ref.read(paymentNotifierProvider.notifier).recordPayment(params);

    if (!mounted) return;
    if (failure != null) {
      setState(() => _phase = _Phase.preview);
      AppToast.error(context, failure.message);
      return;
    }

    AppToast.success(
      context,
      'Transferencia registrada: ${widget.args.billSubtotal.toCop}. '
      'Recuerda legalizarla en caja.',
    );
    context.pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _phase == _Phase.preview ? Colors.black : null,
      appBar: AppBar(
        backgroundColor: _phase == _Phase.preview ? Colors.black : null,
        foregroundColor: _phase == _Phase.preview ? Colors.white : null,
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
            onTakePhoto: () => _pickPhoto(ImageSource.camera),
            onPickFromGallery: () => _pickPhoto(ImageSource.gallery),
          ),
        _Phase.preview => _PreviewBody(
            photo: _capturedPhoto!,
            billSubtotal: widget.args.billSubtotal,
            rotationTurns: _rotationTurns,
            method: _method,
            onMethodChanged: (m) => setState(() => _method = m),
            onRotate: _rotatePhoto,
            onRetake: _retakePhoto,
            onRegister: _recordPayment,
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
                  style: AppTextStyles.statusBadge
                      .copyWith(color: AppColors.statusBlue),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  billSubtotal.toCop,
                  style: AppTextStyles.receiptTotal.copyWith(
                    fontSize: 34,
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.brand, size: AppDimensions.iconSm),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  'Toma una foto clara del comprobante. Se guarda en '
                  '"Bonanza_Transferencias" y podrás verla en Comprobantes.',
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
                      style:
                          AppTextStyles.labelLarge.copyWith(color: Colors.white),
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
                    label: Text('GALERÍA', style: AppTextStyles.labelMedium),
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

// ── Preview phase (foto + método + registrar) ─────────────────────────────────

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.photo,
    required this.billSubtotal,
    required this.rotationTurns,
    required this.method,
    required this.onMethodChanged,
    required this.onRotate,
    required this.onRetake,
    required this.onRegister,
  });

  final XFile photo;
  final int billSubtotal;
  final int rotationTurns;
  final TransferMethod method;
  final ValueChanged<TransferMethod> onMethodChanged;
  final VoidCallback onRotate;
  final VoidCallback onRetake;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          child: RotatedBox(
            quarterTurns: rotationTurns,
            child: Image.file(File(photo.path), fit: BoxFit.contain),
          ),
        ),
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.space32,
              AppDimensions.pagePaddingH,
              AppDimensions.space24,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Comprobante por ${billSubtotal.toCop}',
                    style:
                        AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // ── Plataforma (chips compactos, Nequi por defecto) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: TransferMethod.values.map((m) {
                      final selected = m == method;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onMethodChanged(m);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? m.displayColor.withOpacity(0.3)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    selected ? m.displayColor : Colors.white30,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              m.displayLabel,
                              style: AppTextStyles.labelMedium.copyWith(
                                color:
                                    selected ? Colors.white : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppDimensions.buttonHeightMd,
                          child: OutlinedButton.icon(
                            onPressed: onRetake,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white54, width: 2),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(
                              'CAMBIAR',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: AppDimensions.buttonHeightMd,
                          child: FilledButton.icon(
                            onPressed: onRegister,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.statusGreen,
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              'REGISTRAR PAGO',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: Colors.black),
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
