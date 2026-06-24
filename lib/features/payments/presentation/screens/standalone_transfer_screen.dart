import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/gallery/gallery_saver.dart';
import '../utils/photo_rotation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/payment_receipt_entity.dart';

/// Standalone transfer-photo capture — no linked payment or table session.
///
/// Lets the waiter save a transfer receipt photo (camera or gallery) with a
/// manually-entered amount and platform, storing it in Bonanza_Transferencias
/// without creating any Isar record.
class StandaloneTransferScreen extends StatefulWidget {
  const StandaloneTransferScreen({super.key});

  @override
  State<StandaloneTransferScreen> createState() =>
      _StandaloneTransferScreenState();
}

enum _Phase { initial, preview, saving }

class _StandaloneTransferScreenState extends State<StandaloneTransferScreen> {
  _Phase _phase = _Phase.initial;
  XFile? _photo;
  int _rotationTurns = 0;

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

  // ── Details sheet ────────────────────────────────────────────────────────────

  Future<void> _showDetailsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailsSheet(onConfirm: _savePhoto),
    );
  }

  // ── Save file (no Isar — file copy + gallery only) ───────────────────────────

  Future<void> _savePhoto({
    required int amount,
    required TransferMethod method,
  }) async {
    if (_photo == null) return;
    setState(() => _phase = _Phase.saving);

    try {
      final now = DateTime.now();
      final effectivePath =
          await applyPhotoRotation(_photo!.path, _rotationTurns);
      final dir = await _bonanzaTransferDir();
      final filename = 'suelta_${now.millisecondsSinceEpoch}.jpg';
      final destPath = '${dir.path}/$filename';
      await File(effectivePath).copy(destPath);

      await GallerySaver.saveImage(
        sourcePath: effectivePath,
        fileName: filename,
      );

      if (!mounted) return;
      setState(() => _phase = _Phase.preview);
      await _showConfirmation(amount: amount, method: method);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.preview);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la foto: $e'),
          backgroundColor: AppColors.statusRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Directory> _bonanzaTransferDir() async {
    final Directory base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final dir = Directory('${base.path}/Bonanza_Transferencias');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _showConfirmation({
    required int amount,
    required TransferMethod method,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.statusGreen,
          size: 48,
        ),
        title: Text(
          'Foto guardada',
          style: AppTextStyles.headlineSmall,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${method.displayLabel} · ${amount.toCop}',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.statusBlue,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'El comprobante se guardó en Bonanza_Transferencias.',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.lightOnSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusGreen,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text('LISTO'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final onBlack = _phase == _Phase.preview;
    return Scaffold(
      backgroundColor: onBlack ? Colors.black : null,
      appBar: AppBar(
        backgroundColor: onBlack ? Colors.black : null,
        foregroundColor: onBlack ? Colors.white : null,
        title: Text(
          'Captura de Transferencia',
          style: AppTextStyles.headlineSmall.copyWith(
            color: onBlack ? Colors.white : null,
          ),
        ),
      ),
      body: switch (_phase) {
        _Phase.initial => _InitialBody(
            onTakePhoto: _openCamera,
            onPickFromGallery: _openGallery,
          ),
        _Phase.preview => _PreviewBody(
            photo: _photo!,
            rotationTurns: _rotationTurns,
            onRotate: _rotatePhoto,
            onRetake: _retake,
            onContinue: _showDetailsSheet,
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
          // ── Instruction card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space20),
            decoration: BoxDecoration(
              color: AppColors.statusBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: AppColors.statusBlue.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPROBANTE SUELTO',
                  style: AppTextStyles.statusBadge.copyWith(
                    color: AppColors.statusBlue,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  'Captura un comprobante de transferencia que no esté '
                  'vinculado a una mesa.',
                  style: AppTextStyles.bodyMedium.copyWith(
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

          // ── Capture buttons ───────────────────────────────────────────
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

// ── Preview phase ─────────────────────────────────────────────────────────────

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.photo,
    required this.rotationTurns,
    required this.onRotate,
    required this.onRetake,
    required this.onContinue,
  });

  final XFile photo;
  final int rotationTurns;
  final VoidCallback onRotate;
  final VoidCallback onRetake;
  final VoidCallback onContinue;

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
                  Colors.black.withValues(alpha: 0.85),
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
              child: Row(
                children: [
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
          CircularProgressIndicator(),
          SizedBox(height: AppDimensions.space16),
          Text('Guardando comprobante…'),
        ],
      ),
    );
  }
}

// ── Details sheet ─────────────────────────────────────────────────────────────

class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet({required this.onConfirm});

  final Future<void> Function({
    required int amount,
    required TransferMethod method,
  }) onConfirm;

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  TransferMethod? _method;
  final _amountCtrl = TextEditingController();
  int _amount = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = _method != null && _amount > 0 && !_isSaving;

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
                'Detalles del comprobante',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: AppDimensions.space20),

              // ── Amount ────────────────────────────────────────────────
              Text(
                'MONTO TRANSFERIDO',
                style: AppTextStyles.statusBadge.copyWith(
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandSeparatorFormatter(),
                ],
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0',
                ),
                onChanged: (raw) {
                  final digits = raw.replaceAll('.', '');
                  setState(() => _amount = int.tryParse(digits) ?? 0);
                },
              ),

              const SizedBox(height: AppDimensions.space20),

              // ── Platform picker ───────────────────────────────────────
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
                  final isSelected = _method == method;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _method = method);
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
                              ? method.displayColor.withValues(alpha: 0.15)
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

              const SizedBox(height: AppDimensions.space32),

              // ── Save button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeightLg,
                child: FilledButton.icon(
                  onPressed: canSave
                      ? () async {
                          setState(() => _isSaving = true);
                          Navigator.of(context).pop();
                          await widget.onConfirm(
                            amount: _amount,
                            method: _method!,
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusBlue,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    'GUARDAR COMPROBANTE',
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

// ── Thousand-separator formatter ───────────────────────────────────────────────

class _ThousandSeparatorFormatter extends TextInputFormatter {
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
