import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/settings/bar_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/receipt_paper.dart';
import '../../../../core/widgets/receipt_widgets.dart';
import '../../data/models/shift_snapshot.dart';
import '../providers/shift_history_providers.dart';

/// Detalle de un turno finalizado — todos los totales guardados en el
/// [ShiftSnapshot], sin truncar, en formato tiquete.
///
/// Nota honesta: solo existen los TOTALES financieros de ese turno. Las
/// mesas y productos individuales se borran al finalizar la jornada
/// (Cierre Blindado), así que este detalle no puede reconstruir "qué se
/// vendió" — solo el resumen de dinero que ya quedó guardado.
class ShiftHistoryDetailScreen extends ConsumerWidget {
  const ShiftHistoryDetailScreen({super.key, required this.shiftId});

  final int shiftId;

  static final _dateFormat = DateFormat("EEEE d 'de' MMMM yyyy · HH:mm", 'es_CO');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(shiftSnapshotByIdProvider(shiftId));
    final barName = ref.watch(barNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de turno', style: AppTextStyles.headlineSmall),
        actions: [
          snapshotAsync.maybeWhen(
            data: (s) => s == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Compartir',
                    onPressed: () => _share(s, barName),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error al cargar el turno.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusRed)),
        ),
        data: (snapshot) => snapshot == null
            ? Center(
                child: Text('Este turno ya no existe.',
                    style: AppTextStyles.bodyMedium),
              )
            : _DetailBody(snapshot: snapshot, barName: barName, dateFormat: _dateFormat),
      ),
    );
  }

  void _share(ShiftSnapshot s, String barName) {
    final lines = [
      '📊 $barName — Resumen de Turno',
      _dateFormat.format(s.snapshotAt),
      '──────────────────────────────',
      'Base inicial:        ${s.initialBase.toCop}',
      'Incrementos:          ${s.totalIncreases.toCop}',
      'Reducciones:         -${s.totalDecreases.toCop}',
      if (s.totalLiquorDebt != 0) 'Deuda licor:          ${s.totalLiquorDebt.toCop}',
      'Deuda total:          ${s.totalDebt.toCop}',
      '',
      'Transferencias:       ${s.verifiedTransfersTotal.toCop}',
      'Efectivo cobrado:     ${s.cashPaymentsTotal.toCop}',
      'Servido (productos): ${s.servedStandardItemsTotal.toCop}',
      if (s.transferTipsTotal > 0) 'Propinas:             ${s.transferTipsTotal.toCop}',
      '',
      'Efectivo en mano:     ${s.cashInHand.toCop}',
      '──────────────────────────────',
      'UTILIDAD NETA:        ${s.netProfit.toSignedCop}',
    ];
    Share.share(lines.join('\n'), subject: 'Resumen de turno — $barName');
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.snapshot,
    required this.barName,
    required this.dateFormat,
  });

  final ShiftSnapshot snapshot;
  final String barName;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final profitColor =
        snapshot.netProfit >= 0 ? AppColors.secondaryDark : AppColors.statusRed;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ReceiptPaper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              barName.toUpperCase(),
              style: AppTextStyles.receiptTitle.copyWith(color: AppColors.paperInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(snapshot.snapshotAt),
              style: AppTextStyles.receiptSmall.copyWith(color: AppColors.paperInkSoft),
              textAlign: TextAlign.center,
            ),
            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 12)),

            Text('BASE', style: AppTextStyles.receiptBodyBold.copyWith(color: AppColors.paperInk)),
            const SizedBox(height: 4),
            ReceiptRow(label: 'Base inicial', value: snapshot.initialBase.toCop),
            ReceiptRow(label: 'Incrementos', value: '+${snapshot.totalIncreases.toCop}'),
            ReceiptRow(label: 'Reducciones', value: '-${snapshot.totalDecreases.toCop}'),
            if (snapshot.totalLiquorDebt != 0)
              ReceiptRow(
                label: 'Deuda por licor',
                value: snapshot.totalLiquorDebt.toCop,
                color: AppColors.statusPurple,
              ),
            const SizedBox(height: 6),
            ReceiptRow(
              label: 'DEUDA TOTAL',
              value: snapshot.totalDebt.toCop,
              bold: true,
            ),

            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 12)),

            Text('COBROS', style: AppTextStyles.receiptBodyBold.copyWith(color: AppColors.paperInk)),
            const SizedBox(height: 4),
            ReceiptRow(label: 'Transferencias verificadas', value: snapshot.verifiedTransfersTotal.toCop),
            ReceiptRow(label: 'Efectivo cobrado', value: snapshot.cashPaymentsTotal.toCop),
            ReceiptRow(label: 'Servido (productos)', value: '-${snapshot.servedStandardItemsTotal.toCop}'),
            if (snapshot.transferTipsTotal > 0)
              ReceiptRow(
                label: 'Propinas de transferencia',
                value: snapshot.transferTipsTotal.toCop,
                color: AppColors.primaryDark,
              ),
            const SizedBox(height: 6),
            ReceiptRow(
              label: 'SALDO DISPONIBLE',
              value: snapshot.availableBalance.toCop,
              bold: true,
            ),

            const DashedDivider(padding: EdgeInsets.symmetric(vertical: 12)),

            ReceiptRow(label: 'Efectivo en mano', value: snapshot.cashInHand.toCop),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('UTILIDAD NETA',
                    style: AppTextStyles.receiptTotal.copyWith(color: AppColors.paperInk)),
                Text(snapshot.netProfit.toSignedCop,
                    style: AppTextStyles.receiptTotal.copyWith(color: profitColor)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Solo se guardan los totales financieros de este turno —\n'
              'las mesas y productos ya no existen tras el Cierre.',
              style: AppTextStyles.receiptSmall.copyWith(
                color: AppColors.paperInkSoft,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
