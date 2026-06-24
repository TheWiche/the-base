/// UI string constants in Spanish (Colombian locale).
///
/// All user-facing text lives here so future i18n extraction is trivial.
abstract final class AppStrings {
  // ── App ────────────────────────────────────────────────────────────
  static const String appName = 'The Base';
  static const String appTagline = 'The Base';

  // ── Navigation ─────────────────────────────────────────────────────
  static const String navDashboard = 'Inicio';
  static const String navRadar = 'El Radar';
  static const String navTables = 'Mesas';
  static const String navProducts = 'Catálogo';
  static const String navCierre = 'Cierre';

  // ── Base Management ────────────────────────────────────────────────
  static const String baseLabel = 'Base del Mesero';
  static const String baseInitial = 'Base Inicial';
  static const String baseIncrease = 'Aumento de Base';
  static const String baseAvailable = 'Saldo Disponible';
  static const String baseDebt = 'Deuda Total';
  static const String baseTips = 'Propinas Netas';
  static const String confirmIncrease = '¿Agregar \$100.000 a la base?';
  static const String increaseSuccess = 'Base aumentada exitosamente';

  // ── Tables ─────────────────────────────────────────────────────────
  static const String tablesTitle = 'Mesas';
  static const String tableNew = 'Nueva Mesa';
  static const String tableOpen = 'Mesa Abierta';
  static const String tableClosed = 'Mesa Cerrada';
  static const String tableNumber = 'Mesa';
  static const String tablePeople = 'Personas';
  static const String tableAddProduct = 'Agregar Producto';

  // ── Orders / El Radar ──────────────────────────────────────────────
  static const String radarTitle = 'El Radar';
  static const String radarEmpty = 'Sin pedidos pendientes';
  static const String radarViewChronological = 'Por Hora';
  static const String radarViewGrouped = 'Por Mesa';
  static const String orderPending = 'Pendiente';
  static const String orderDelivered = 'Entregado';
  static const String orderCancelled = 'Cancelado';
  static const String elapsedTime = 'Hace';

  // ── Products ───────────────────────────────────────────────────────
  static const String productsTitle = 'Catálogo';
  static const String productLiquor = 'Licor';
  static const String productFood = 'Cocina';
  static const String productDrink = 'Bebida';

  // ── Billing ────────────────────────────────────────────────────────
  static const String billingTitle = 'Cobrar';
  static const String billingSubtotal = 'Subtotal';
  static const String billingTotal = 'Total';
  static const String billingSelectItems = 'Seleccionar ítems';
  static const String billingPayCash = 'Pagar en Efectivo';
  static const String billingPayTransfer = 'Pagar por Transferencia';
  static const String billingChange = 'Cambio';
  static const String billingAmountReceived = 'Efectivo recibido';
  static const String billingPaid = 'Pagado';
  static const String billingPartialPaid = 'Pago Parcial';

  // ── Transfer / Camera ──────────────────────────────────────────────
  static const String transferTitle = 'Transferencia';
  static const String transferNequi = 'Nequi';
  static const String transferDaviplata = 'Daviplata';
  static const String transferOther = 'Otro';
  static const String transferPhotoPrompt = 'Toma la foto del comprobante';
  static const String transferRetake = 'Repetir Foto';
  static const String transferConfirm = 'Confirmar Transferencia';
  static const String transferPending = 'Pendiente de Legalización';
  static const String transferLegalized = 'Legalizada';
  static const String transferFolderName = 'TheBase_Transferencias';

  // ── Cierre Blindado ────────────────────────────────────────────────
  static const String cierreTitle = 'Cierre del Día';
  static const String cierreBlocked = 'No se puede generar el cierre';
  static const String cierreBlockedRadar =
      'Hay pedidos pendientes en El Radar.';
  static const String cierreBlockedTables =
      'Hay mesas con saldo pendiente.';
  static const String cierreBlockedTransfers =
      'Hay transferencias sin legalizar.';
  static const String cierreGenerate = 'Generar Cierre';
  static const String cierreReport = 'Reporte de Cierre';

  // ── General actions ────────────────────────────────────────────────
  static const String actionConfirm = 'Confirmar';
  static const String actionCancel = 'Cancelar';
  static const String actionSave = 'Guardar';
  static const String actionDelete = 'Eliminar';
  static const String actionEdit = 'Editar';
  static const String actionClose = 'Cerrar';
  static const String actionRetry = 'Reintentar';
  static const String actionBack = 'Volver';

  // ── Error messages ─────────────────────────────────────────────────
  static const String errorGeneric = 'Ocurrió un error inesperado.';
  static const String errorNetwork =
      'Sin conexión. Verifica tu red e intenta de nuevo.';
  static const String errorCamera = 'No se pudo acceder a la cámara.';
  static const String errorStorage = 'Error al guardar el archivo.';
  static const String errorPermission =
      'Permiso denegado. Habilítalo en Configuración.';
  static const String errorNotFound = 'Recurso no encontrado.';
}
