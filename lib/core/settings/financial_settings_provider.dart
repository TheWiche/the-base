import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/financial_constants.dart';
import '../theme/theme_provider.dart';

/// Base inicial y paso de incremento/decremento configurables por el mesero.
/// Persistidos en SharedPreferences; caen a [FinancialConstants] si no se
/// han personalizado. Editables desde Ajustes.
const String _kBaseAmountKey = 'thebase_base_amount';
const String _kIncrementStepKey = 'thebase_increment_step';

class FinancialSettings {
  const FinancialSettings({required this.baseAmount, required this.incrementStep});

  final int baseAmount;
  final int incrementStep;
}

class FinancialSettingsNotifier extends Notifier<FinancialSettings> {
  @override
  FinancialSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return FinancialSettings(
      baseAmount:
          prefs.getInt(_kBaseAmountKey) ?? FinancialConstants.initialBase,
      incrementStep:
          prefs.getInt(_kIncrementStepKey) ?? FinancialConstants.baseIncrement,
    );
  }

  void setBaseAmount(int amount) {
    if (amount <= 0) return;
    state = FinancialSettings(baseAmount: amount, incrementStep: state.incrementStep);
    ref.read(sharedPreferencesProvider).setInt(_kBaseAmountKey, amount);
  }

  void setIncrementStep(int amount) {
    if (amount <= 0) return;
    state = FinancialSettings(baseAmount: state.baseAmount, incrementStep: amount);
    ref.read(sharedPreferencesProvider).setInt(_kIncrementStepKey, amount);
  }
}

final financialSettingsProvider =
    NotifierProvider<FinancialSettingsNotifier, FinancialSettings>(
  FinancialSettingsNotifier.new,
);
