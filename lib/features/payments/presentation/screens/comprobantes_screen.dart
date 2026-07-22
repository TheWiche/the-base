import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/gallery/transfer_photos.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Visor de comprobantes: muestra las fotos guardadas en Bonanza_Transferencias
/// (capturas sueltas y comprobantes de mesas). Tap → ver en grande + compartir.
class ComprobantesScreen extends StatefulWidget {
  const ComprobantesScreen({super.key});

  @override
  State<ComprobantesScreen> createState() => _ComprobantesScreenState();
}

class _ComprobantesScreenState extends State<ComprobantesScreen> {
  late Future<List<File>> _future;

  @override
  void initState() {
    super.initState();
    _future = listTransferPhotos();
  }

  void _reload() => setState(() => _future = listTransferPhotos());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comprobantes', style: AppTextStyles.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: FutureBuilder<List<File>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final files = snap.data ?? [];
          if (files.isEmpty) return const _Empty();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: files.length,
            itemBuilder: (context, i) => _PhotoTile(
              file: files[i],
              onTap: () => _openViewer(files[i]),
            ),
          );
        },
      ),
    );
  }

  void _openViewer(File file) {
    final modified = file.statSync().modified;
    final label = DateFormat("d MMM yyyy · HH:mm", 'es_CO').format(modified);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: InteractiveViewer(child: Image.file(file))),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: AppTextStyles.bodySmall),
                  ),
                  TextButton.icon(
                    onPressed: () => Share.shareXFiles([XFile(file.path)]),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.file, required this.onTap});

  final File file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final modified = file.statSync().modified;
    final label = DateFormat('d MMM · HH:mm', 'es_CO').format(modified);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.mono.copyWith(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Icon(Icons.receipt_rounded,
                  size: 16, color: AppColors.primary.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 72, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Sin comprobantes', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Las fotos de transferencias y capturas sueltas\naparecerán aquí.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
