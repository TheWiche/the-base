import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sub_cuenta.dart';

class SubCuentaNotifier extends StateNotifier<SubCuentaState> {
  SubCuentaNotifier() : super(const SubCuentaState());

  int _nextId = 1;

  /// Enters split mode with two empty cuentas.
  void activate() {
    _nextId = 1;
    final c1 = SubCuenta(id: _nextId++, label: 'Cuenta 1');
    final c2 = SubCuenta(id: _nextId++, label: 'Cuenta 2');
    state = SubCuentaState(cuentas: [c1, c2], isActive: true);
  }

  /// Exits split mode and clears all assignments.
  void deactivate() {
    _nextId = 1;
    state = const SubCuentaState();
  }

  void addCuenta() {
    final label = 'Cuenta ${state.cuentas.length + 1}';
    final cuenta = SubCuenta(id: _nextId++, label: label);
    state = SubCuentaState(
      cuentas: [...state.cuentas, cuenta],
      isActive: true,
    );
  }

  /// Removes a cuenta. Enforces a minimum of 2 cuentas.
  void removeCuenta(int cuentaId) {
    if (state.cuentas.length <= 2) return;
    final cuentas = state.cuentas.where((c) => c.id != cuentaId).toList();
    state = SubCuentaState(cuentas: cuentas, isActive: true);
  }

  /// Assigns [itemId] to [cuentaId], removing it from any previous owner.
  void assignItem(int itemId, int cuentaId) {
    final cuentas = state.cuentas.map((c) {
      if (c.id == cuentaId) return c.addItem(itemId);
      return c.removeItem(itemId);
    }).toList();
    state = SubCuentaState(cuentas: cuentas, isActive: true);
  }

  /// Returns [itemId] to the unassigned pool.
  void unassignItem(int itemId) {
    final cuentas = state.cuentas.map((c) => c.removeItem(itemId)).toList();
    state = SubCuentaState(cuentas: cuentas, isActive: true);
  }
}

/// Scoped per table session. Cleared automatically when [BillingScreen] leaves
/// the widget tree (autoDispose).
final subCuentaProvider = StateNotifierProvider.family
    .autoDispose<SubCuentaNotifier, SubCuentaState, int>(
  (ref, sessionId) => SubCuentaNotifier(),
);
