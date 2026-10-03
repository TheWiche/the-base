## Novedades en The Base v1.12.0 🚀

### 📲 Descargas Disponibles
- **`the-base.apk` / `the-base-arm64-v8a.apk` (25.7 MB)** — **[RECOMENDADA / PRINCIPAL]** Optimizada para teléfonos actuales (Android de 64 bits). Rendimiento ultra fluido, menor consumo de batería y descarga liviana.
- **`the-base-universal.apk` (64.4 MB)** — Versión universal compatible con cualquier teléfono Android o emulador.
- **`the-base-armeabi-v7a.apk` (23.3 MB)** — Optimizada para dispositivos Android antiguos de 32 bits.

---

### 🎨 Consolidación del Sistema de Diseño (Dark Premium)
- **Superficies y Fondos Unificados**: Fondo principal en carbón mate (`#121212` / `#18191A`), tarjetas en grafito pulido (`#242526` / `#2D2F31`) con delineado sutil y radio estandarizado de 16px.
- **Ergonomía Táctil y Botonera Estándar**: Botones de acción principales estandarizados a 52–56px de altura y bordes redondeados con respuesta háptica en cada interacción.
- **El Radar 2.0**: Eliminación de tiques rasgados beige; comanda y pedidos modernizados a tarjetas de grafito de alto contraste con badges ámbar y botón verde esmeralda "Entregar todo".
- **Mesas e Historiales**: Tarjetas de mesa (`_TableCard`), auditoría de mesas cerradas e historial de turnos actualizados a tarjetas Dark Premium.

---

### 🍾 Finanzas y Liquidación de Botellas en Caja
- **Liquidación de Botellas en Turno**: Nueva funcionalidad en la Billetera para liquidar o pagar de contado en la caja del establecimiento el valor de botellas de licor consumidas.
- **Ajuste Contable Automático**: Al liquidar, se descuenta de forma inmediata de la `Deuda por Licor` y de la `Deuda Total con el Local`, sin afectar negativamente el saldo base del mesero.
- **Cobro Directo y Limpio**: Supresión definitiva del flujo de pago mixto innecesario; flujos directos de Efectivo y Transferencia con visualización destacada de notas y modificadores.

---

### 🧪 Calidad y Pruebas
- **Pruebas End-to-End Automáticas**: Suite E2E (`integration_test/app_e2e_test.dart`) verificando arranque limpio sin mesas residuales, consistencia visual oscura, persistencia del banner global de transferencias y liquidación de botellas.
- **Suite de Pruebas Unitarias**: 19/19 pruebas superadas exitosamente.

