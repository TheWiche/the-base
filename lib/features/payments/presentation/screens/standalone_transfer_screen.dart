import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/gallery/gallery_saver.dart';
import '../../../../core/gallery/transfer_photos.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../utils/photo_rotation.dart';

/// Standalone transfer-photo capture — no linked payment or table session.
///
/// Foto → guardar directo en Bonanza_Transferencias (sin hoja de detalles,
/// sin registro Isar). Visible después desde "Comprobantes".
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

  // ── Save file (no Isar — file copy + gallery only) ───────────────────────────
  // Sin hoja de detalles: foto → guardar directo → toast (menos clicks).

  Future<void> _savePhoto() async {
    if (_photo == null) return;
    setState(() => _phase = _Phase.saving);

    try {
      final now = DateTime.now();
      final effectivePath =
          await applyPhotoRotation(_photo!.path, _rotationTurns);
      final dir = await transferPhotosDir();
      final filename = 'suelta_${now.millisecondsSinceEpoch}.jpg';
      final destPath = '${dir.path}/$filename';
      await File(effectivePath).copy(destPath);

      await GallerySaver.saveImage(
        sourcePath: effectivePath,
        fileName: filename,
      );

      if (!mounted) return;
      AppToast.success(
          context, 'Comprobante guardado. Míralo en "Comprobantes".');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.preview);
      AppToast.error(context, 'No se pudo guardar la foto: $e');
    }
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
            onContinue: _savePhoto,
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
                          'GUARDAR',
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

