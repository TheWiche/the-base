import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/gallery/gallery_saver.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/payment_receipt_entity.dart';
import '../providers/payment_providers.dart';
import '../utils/photo_rotation.dart';

/// Captura de transferencia independiente / huérfana (sin mesa asociada).
///
/// Permite capturar pagos directos, propinas sueltas o anticipos.
/// Se persiste como un [PaymentReceipt] con tableSessionId = 0 y
/// isLegalizedInCaja = false, integrándose de inmediato en el Banner Global
/// y en la lista de comprobantes pendientes de caja.
class StandaloneTransferScreen extends ConsumerStatefulWidget {
  const StandaloneTransferScreen({super.key});

  @override
  ConsumerState<StandaloneTransferScreen> createState() =>
      _StandaloneTransferScreenState();
}

enum _Phase { initial, preview, saving }

class _StandaloneTransferScreenState
    extends ConsumerState<StandaloneTransferScreen> {
  _Phase _phase = _Phase.initial;
  XFile? _photo;
  int _rotationTurns = 0;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransferMethod _transferMethod = TransferMethod.nequi;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Photo capture / pick ─────────────────────────────────────────────────────

  Future<void> _openCamera() => _pickPhoto(ImageSource.camera);
  Future<void> _openGallery() => _pickPhoto(ImageSource.gallery);

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
      _photo = file;
      _phase = _Phase.preview;
    });
  }

  void _retake() {
    setState(() {
      _photo = null;
      _phase = _Phase.initial;
      _rotationTurns = 0;
    });
  }

  void _rotatePhoto() {
    setState(() => _rotationTurns = (_rotationTurns + 1) % 4);
  }

  // ── Save standalone transfer ─────────────────────────────────────────────────

  Future<void> _saveTransfer() async {
    if (_photo == null) return;

    final rawAmount =
        int.tryParse(_amountController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (rawAmount <= 0) {
      AppToast.error(context, 'Ingresa el monto de la transferencia.');
      return;
    }

    setState(() => _phase = _Phase.saving);

    try {
      final effectivePath =
          await applyPhotoRotation(_photo!.path, _rotationTurns);

      final note = _noteController.text.trim();
      final result =
          await ref.read(paymentRepositoryProvider).recordStandaloneTransfer(
                amount: rawAmount,
                photoSourcePath: effectivePath,
                transferMethod: _transferMethod,
                note: note.isNotEmpty ? note : 'Transferencia independiente',
              );

      if (!mounted) return;

      if (result case Err(:final failure)) {
        setState(() => _phase = _Phase.preview);
        AppToast.error(context, 'Error al guardar: ${failure.message}');
        return;
      }

      // Guardar también en la galería de fotos del teléfono
      final now = DateTime.now();
      await GallerySaver.saveImage(
        sourcePath: effectivePath,
        fileName: 'suelta_${now.millisecondsSinceEpoch}.jpg',
      );

      if (!mounted) return;
      AppToast.success(
        context,
        '⚡ Transferencia de ${rawAmount.toCop} registrada. ¡Pendiente por mostrar en caja!',
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.preview);
      AppToast.error(context, 'No se pudo guardar la transferencia: $e');
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transferencia Independiente',
          style: AppTextStyles.headlineSmall,
        ),
      ),
      body: switch (_phase) {
        _Phase.initial => _InitialBody(
            onTakePhoto: _openCamera,
            onPickFromGallery: _openGallery,
          ),
        _Phase.preview => _PreviewWithDetailsBody(
            photo: _photo!,
            rotationTurns: _rotationTurns,
            amountController: _amountController,
            noteController: _noteController,
            transferMethod: _transferMethod,
            onMethodChanged: (m) => setState(() => _transferMethod = m),
            onRotate: _rotatePhoto,
            onRetake: _retake,
            onSave: _saveTransfer,
          ),
        _Phase.saving => const _SavingOverlay(),
      },
    );
  }
}

// ── Initial phase ─────────────────────────────────────────────────────────────

class _InitialBody extends StatelessWidget {
  const _InitialBody({
    required this.onTakePhoto,
    required this.onPickFromGallery,
  });

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
              color: const Color(0xFFE65100).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: const Color(0xFFE65100).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFE65100),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PAGO SUELTO / ANTICIPO',
                      style: AppTextStyles.statusBadge.copyWith(
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  'Captura un comprobante de transferencia que no pertenezca '
                  'a ninguna mesa (pagos en barra, propinas sueltas o anticipos).\n\n'
                  'Se sumará automáticamente a las transferencias por legalizar en caja.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
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
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text(
                      'TOMAR FOTO',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

// ── Preview + Details phase (Thumb Zone optimized) ────────────────────────────

class _PreviewWithDetailsBody extends StatelessWidget {
  const _PreviewWithDetailsBody({
    required this.photo,
    required this.rotationTurns,
    required this.amountController,
    required this.noteController,
    required this.transferMethod,
    required this.onMethodChanged,
    required this.onRotate,
    required this.onRetake,
    required this.onSave,
  });

  final XFile photo;
  final int rotationTurns;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final TransferMethod transferMethod;
  final ValueChanged<TransferMethod> onMethodChanged;
  final VoidCallback onRotate;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  static const _quickAmounts = [10000, 20000, 50000, 100000];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── Previsualización compacta de la foto con rotación ─────────────
        Expanded(
          flex: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black,
                child: InteractiveViewer(
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: rotationTurns,
                      child: Image.file(
                        File(photo.path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.rotate_right_rounded,
                        color: Colors.white),
                    tooltip: 'Girar 90°',
                    onPressed: onRotate,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  child: InkWell(
                    onTap: onRetake,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Cambiar',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Formulario de datos en la Thumb Zone ───────────────────────────
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLg),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePaddingH,
                AppDimensions.space16,
                AppDimensions.pagePaddingH,
                AppDimensions.space16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de Monto
                  Text(
                    'VALOR DE LA TRANSFERENCIA',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFE65100),
                      ),
                      hintText: '0',
                      hintStyle: AppTextStyles.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.darkDisabled
                            : AppColors.lightDisabled,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(
                          color: const Color(0xFFE65100).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: const Color(0xFFE65100),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Chips de montos rápidos
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final q in _quickAmounts)
                        ActionChip(
                          label: Text(q.toCop),
                          onPressed: () {
                            amountController.text = q.toString();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Selector de Plataforma (Nequi / Daviplata / Otro)
                  Text(
                    'MÉTODO',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final m in TransferMethod.values) ...[
                        Expanded(
                          child: ChoiceChip(
                            avatar: Icon(
                              m.displayIcon,
                              size: 16,
                              color: transferMethod == m
                                  ? Colors.white
                                  : m.displayColor,
                            ),
                            label: Text(m.displayLabel),
                            selected: transferMethod == m,
                            selectedColor: m.displayColor,
                            labelStyle: TextStyle(
                              color: transferMethod == m
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.lightOnSurface),
                              fontWeight: transferMethod == m
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) => onMethodChanged(m),
                          ),
                        ),
                        if (m != TransferMethod.values.last)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Concepto / Nota opcional
                  Text(
                    'CONCEPTO (OPCIONAL)',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.lightOnSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Ej. Pago barra, Propina suelta, Anticipo',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Botón principal de guardado
                  SizedBox(
                    height: AppDimensions.buttonHeightLg,
                    child: FilledButton.icon(
                      onPressed: onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        foregroundColor: Colors.white,
                        textStyle: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('GUARDAR TRANSFERENCIA'),
                    ),
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

// ── Saving overlay ────────────────────────────────────────────────────────────

class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
          ),
          SizedBox(height: AppDimensions.space16),
          Text(
            'Guardando y registrando transferencia…',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
