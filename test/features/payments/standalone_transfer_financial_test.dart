import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_base/features/base_management/domain/entities/wallet_summary.dart';
import 'package:the_base/features/base_management/presentation/providers/base_wallet_providers.dart';
import 'package:the_base/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:the_base/features/payments/domain/entities/payment_receipt_entity.dart';

void main() {
  group('Standalone Transfer Financial Integrity Rules', () {
    test('WalletSummary strictly ignores standalone transfers in balance and debt, but includes them in totalSold', () {
      const summary = WalletSummary(
        transactions: [],
        initialBase: 100000,
        totalIncreases: 50000,
        totalDecreases: 10000,
        totalLiquorDebt: 0,
        cashPaymentsTotal: 20000,
        verifiedTransfersTotal: 30000,
        servedStandardItemsTotal: 15000,
        standaloneTransfersTotal: 80000, // Informative loose receipt
      );

      // Available Balance = initialBase + totalIncreases - totalDecreases + verifiedTransfersTotal + cashPaymentsTotal - servedStandardItemsTotal
      // = 100,000 + 50,000 - 10,000 + 30,000 + 20,000 - 15,000 = 175,000
      // Under NO circumstances should standaloneTransfersTotal (80,000) alter availableBalance!
      expect(summary.availableBalance, 175000);

      // Total Debt = initialBase + totalIncreases - totalDecreases + totalLiquorDebt
      // = 100,000 + 50,000 - 10,000 + 0 = 140,000
      expect(summary.totalDebt, 140000);

      // Total Sold / Facturado = cashPaymentsTotal + verifiedTransfersTotal + standaloneTransfersTotal
      // = 20,000 + 30,000 + 80,000 = 130,000
      expect(summary.totalSold, 130000);
    });

    test('verifiedTransfersTotalProvider excludes tableSessionId == 0 and standaloneTransfersTotalProvider aggregates them', () async {
      final now = DateTime.now();
      final receipts = [
        // Legalized table transfer -> counts in verifiedTransfersTotal
        PaymentReceiptEntity(
          id: 1,
          tableSessionId: 5,
          amountPaid: 35000,
          changeGiven: 0,
          tipAmount: 0,
          paymentMethod: PaymentMethod.transfer,
          isLegalizedInCaja: true,
          paidAt: now,
        ),
        // Legalized standalone transfer (suelta) -> MUST NOT count in verifiedTransfersTotal!
        PaymentReceiptEntity(
          id: 2,
          tableSessionId: 0,
          amountPaid: 50000,
          changeGiven: 0,
          tipAmount: 0,
          paymentMethod: PaymentMethod.transfer,
          isLegalizedInCaja: true,
          paidAt: now,
        ),
        // Unlegalized standalone transfer (suelta) -> counts in standaloneTransfersTotal
        PaymentReceiptEntity(
          id: 3,
          tableSessionId: 0,
          amountPaid: 25000,
          changeGiven: 0,
          tipAmount: 0,
          paymentMethod: PaymentMethod.transfer,
          isLegalizedInCaja: false,
          paidAt: now,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          allTransferReceiptsProvider.overrideWith(
            (ref) => Stream.value(receipts),
          ),
          servedStandardItemsTotalProvider.overrideWith((ref) => Stream.value(0)),
          cashPaymentsTotalProvider.overrideWith((ref) => Stream.value(0)),
          verifiedLiquorPaymentsTotalProvider.overrideWith((ref) => Stream.value(0)),
          baseWalletProvider.overrideWith(
            () => _FakeBaseWalletNotifier(
              const WalletSummary(
                transactions: [],
                initialBase: 100000,
                totalIncreases: 0,
                totalDecreases: 0,
                totalLiquorDebt: 0,
              ),
            ),
          ),
        ],
      );

      // Allow streams to emit
      await container.read(baseWalletProvider.future);
      await container.read(allTransferReceiptsProvider.future);
      await container.read(servedStandardItemsTotalProvider.future);
      await container.read(cashPaymentsTotalProvider.future);
      await container.read(verifiedLiquorPaymentsTotalProvider.future);

      final verifiedTotal = container.read(verifiedTransfersTotalProvider);
      // Only receipt #1 ($35.000) should be included!
      expect(verifiedTotal, 35000);

      final standaloneTotal = container.read(standaloneTransfersTotalProvider);
      // Both receipt #2 ($50.000) and receipt #3 ($25.000) = $75.000
      expect(standaloneTotal, 75000);

      final enriched = container.read(enrichedWalletSummaryProvider).value!;
      // verifiedTransfersTotal must equal 35,000, NOT 35,000 + 75,000
      expect(enriched.verifiedTransfersTotal, 35000);
      expect(enriched.standaloneTransfersTotal, 75000);

      // Available Balance = 100,000 + 35,000 = 135,000
      expect(enriched.availableBalance, 135000);

      // Total Sold = 35,000 + 75,000 = 110,000
      expect(enriched.totalSold, 110000);
    });
  });
}

class _FakeBaseWalletNotifier extends BaseWalletNotifier {
  _FakeBaseWalletNotifier(this.initial);
  final WalletSummary initial;

  @override
  Future<WalletSummary> build() async => initial;
}
