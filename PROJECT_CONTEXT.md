# PROJECT CONTEXT: The Base — Billetera del Mesero

## 1. Visión General del Proyecto
- **Propósito:** *The Base* (nombre de código de repositorio: *Bonanza*) es una solución móvil integral **offline-first** diseñada para meseros y personal de servicio en bares, discotecas y restaurantes. Resuelve de raíz el descontrol de cuentas, la pérdida de dinero en efectivo, el retraso en la entrega de pedidos de barra/cocina y el fraude o confusión en transferencias bancarias (Nequi, Daviplata, Bancolombia, etc.). Funciona como la billetera operativa y KDS (Kitchen Display System) personal del mesero en su propio dispositivo Android.
- **Estado Actual:** **Producción / MVP Avanzado (Versión 1.10.0+24)**. La aplicación móvil se encuentra completamente construida, compilada en APK distribuible (`the-base.apk`), cuenta con una landing page web estática desplegada mediante GitHub Actions y opera con persistencia local robusta e inmutable de turnos.

---

## 2. Stack Tecnológico y Configuración

### Frontend / Cliente (App Móvil)
- **Framework Principal:** Flutter SDK `>=3.4.0 <4.0.0` (Dart 3), modo `edgeToEdge` bloqueado a orientación vertical (`portraitUp`, `portraitDown`).
- **Gestor de Estado:** `flutter_riverpod: ^2.6.1` (arquitectura declarativa y reactiva mediante `AsyncNotifier`, `AutoDisposeFamilyAsyncNotifier`, `StreamProvider` y `Provider` derivados).
- **Sistema de Rutas y Navegación:** `go_router: ^14.2.8` implementando un `ShellRoute` persistente con barra inferior animada de 5 pestañas y rutas secundarias full-screen con transiciones fluidas personalizadas (`FadeTransition` + `SlideTransition`).
- **Sistema de Diseño e Interfaz:** Tema personalizado "Tiquete" inspirado en rollos de papel térmico analógico:
  - Papel crema (`#F2ECDC`), tinta oscura (`#1A1A22`), acento ámbar/mostaza (`#E0A63C`), verde dinero (`#46B67F`), rojo sello (`#D6483B`) y shell oscuro cálido (`#0B0B10`).
  - Soporte nativo para Modo Oscuro y Modo Claro reactivo con sincronización del `SystemUiOverlayStyle` de Android.
  - Tipografías empaquetadas localmente en `assets/fonts/` (sin dependencia de red ni `google_fonts`): **Nunito** (pesos bold outdoor para la app) y **Space Mono** (Regular y Bold para tiquetes, cifras y comprobantes).
- **Hardware y Multimedia:** `image_picker: ^1.1.2` (cámara y galería), `path_provider: ^2.1.4`, `permission_handler: ^11.3.1`, `image: ^4.3.0` (procesamiento y reorientación de fotos de comprobantes).
- **Notificaciones Locales:** `flutter_local_notifications: ^17.2.4` para recordatorios en segundo plano de pedidos demorados y transferencias pendientes de validación en caja.
- **Canal Nativo Kotlin (Android):** `MethodChannel("com.thebase.app/gallery")` en `MainActivity.kt` para registrar comprobantes de transferencia directamente en el `MediaStore` público (`Pictures/TheBase_Transferencias`).

### Backend / Servicios
- **Arquitectura de Ejecución:** **100% Local / Offline-First / Zero-Cloud Runtime**. No depende de servidores HTTP externos, microservicios remotos ni conexión a internet para el flujo de trabajo del mesero.
- **Landing Web Auxiliar:** Subproyecto en `landing/` construido con Vite 5, JavaScript moderno, CSS modular, generación dinámica de códigos QR con `qrcode: ^1.5.4`, e integración con la API de GitHub Releases para la descarga del APK. Desplegado automáticamente a GitHub Pages vía `.github/workflows/deploy-landing.yml`.

### Persistencia de Datos
- **Motor de Base de Datos:** **Isar Database v3.1.0+1** (`isar`, `isar_flutter_libs`, `isar_generator`). Base de datos embebida NoSQL transaccional de alto rendimiento en C++.
- **Preferencias del Sistema:** `shared_preferences: ^2.3.2` para configuración de nombre de bar, valores base y pasos de incremento, temas y control de migraciones de datos.
- **Colecciones / Modelos de Datos Principales (`IsarService.db`):**
  1. [`WaiterBaseTransaction`](file:///c:/Users/cotes/Documents/Bonanza/lib/features/base_management/data/models/waiter_base_transaction.dart): Libro mayor contable de la base del mesero.
     - Campos: `id`, `type` (`TransactionType`: `initial`, `increase`, `decrease`, `liquorAdjustment`, `liquorSettlement`), `amount` (COP positivo), `timestamp` (indexado), `note` (String?).
  2. [`TableSession`](file:///c:/Users/cotes/Documents/Bonanza/lib/features/tables/data/models/table_session.dart): Agregado raíz de sesión de mesa.
     - Campos: `id`, `tableNumber` (int indexado), `apodo` (String?), `status` (`TableStatus`: `open`, `partiallyPaid`, `closed`), `openedAt` (DateTime indexado), `closedAt` (DateTime?), `verificationCode` (String? SHA-256 de 8 dígitos).
     - Relaciones: `orderItems` (`IsarLinks<OrderItem>`), `payments` (`IsarLinks<PaymentReceipt>`).
  3. [`OrderItem`](file:///c:/Users/cotes/Documents/Bonanza/lib/features/orders/data/models/order_item.dart): Líneas de comanda / pedidos.
     - Campos: `id`, `tableSessionId` (índice compuesto con `isPaid`), `productName`, `productCatalogId`, `price`, `quantity`, `category` (`ProductCategory`: `standard`, `liquor`), `orderedAt` (indexado), `deliveredAt`, `status` (`OrderItemStatus`: `pending`, `delivered`, `cancelled`), `isPaid` (indexado), `paymentReceiptId`, `note`, `menuCategory`, `subcategory`. Backlink: `tableSession`.
  4. [`PaymentReceipt`](file:///c:/Users/cotes/Documents/Bonanza/lib/features/billing/data/models/payment_receipt.dart): Registro de cobro parcial o total.
     - Campos: `id`, `tableSessionId` (indexado), `amountPaid`, `changeGiven`, `tipAmount`, `paymentMethod` (`PaymentMethod`: `cash`, `transfer`), `transferMethodIndex` (`TransferMethod`: `nequi`, `daviplata`, `bancolombia`, `dale`, `otro`), `photoPath`, `supabasePhotoUrl` (legacy/descartado), `isLegalizedInCaja` (indexado), `verificationCode` (String? SHA-256 de 8 dígitos), `paidAt` (indexado). Backlink: `tableSession`.
  5. [`Product`](file:///c:/Users/cotes/Documents/Bonanza/lib/features/products/data/models/product.dart): Catálogo de productos local del menú.
     - Campos: `id`, `name`, `price`, `category` (indexado), `subcategory`, `isComposable` (bool para combinaciones tipo michelada con base de cerveza o soda), `baseCategories` (`List<String>`), `isLiquor` (bool: dispara ajuste contable directo a deuda), `isAvailable` (bool indexado: control de agotados).
  6. [`ShiftSnapshot`](file:///c:/Users/cotes/Documents/Bonanza/lib/features/shift_history/data/models/shift_snapshot.dart): Resumen inmutable del turno finalizado que sobrevive a la limpieza del Cierre Blindado.
     - Campos: `id`, `snapshotAt` (indexado), componentes de base (`initialBase`, `totalIncreases`, `totalDecreases`, `totalLiquorDebt`), componentes de facturación (`verifiedTransfersTotal`, `cashPaymentsTotal`, `servedStandardItemsTotal`, `transferTipsTotal`), cuadre (`cashInHand`, `totalDebt`, `availableBalance`, `netProfit`).

### Variables de Entorno Requeridas
- **No se requieren variables `.env` para la aplicación móvil.** Es una solución autónoma, sin credenciales de terceros ni dependencias en API keys.
- En la automatización de despliegue de la landing page (`deploy-landing.yml`), se utiliza:
  - `NODE_ENV=production`

### Comandos de Ejecución y Ciclo de Vida
- **Generación de código (Isar & Build Runner):**
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Ejecutar en dispositivo / emulador (modo desarrollo):**
  ```bash
  flutter run
  ```
- **Generar APK de producción (Android):**
  ```bash
  flutter build apk --release
  ```
- **Generar Bundle para Google Play (Android):**
  ```bash
  flutter build appbundle --release
  ```
- **Generar íconos de aplicación:**
  ```bash
  dart run flutter_launcher_icons
  ```
- **Ejecutar pruebas automatizadas:**
  ```bash
  flutter test
  ```
- **Landing Web (desarrollo local y build):**
  ```bash
  cd landing
  npm install
  npm run dev      # Servidor local Vite
  npm run build    # Compilación a landing/dist
  ```

---

## 3. Arquitectura del Repositorio

### Árbol de Carpetas y Responsabilidad Técnica
```text
bonanza/
├── .github/workflows/          # CI/CD de GitHub Actions (deploy de la landing a GitHub Pages)
├── android/                    # Código nativo Android (Gradle Kotlin DSL, MainActivity.kt con MethodChannel)
├── assets/
│   ├── fonts/                  # Tipografías offline locales: Nunito-Variable, SpaceMono-Regular, SpaceMono-Bold
│   ├── icon/                   # Íconos generados de la app
│   └── logo/                   # Logotipos oficiales e isotipos (LogoSinTexto.png)
├── landing/                    # Subproyecto web Vite/HTML/CSS para la página promocional y descarga del APK
│   ├── src/                    # JavaScript (QR, temas, consumo de GitHub API) y estilos
│   ├── index.html              # Landing page comercial
│   └── package.json            # Scripts y dependencias de la landing
├── lib/                        # Código fuente principal en Flutter (Clean Architecture)
│   ├── main.dart               # Punto de entrada, configuración de SystemUI, locale 'es_CO', inicialización de Isar y migraciones
│   ├── core/                   # Módulos transversales y utilidades base
│   │   ├── constants/          # Constantes inmutables financieras, categorías de menú y textos
│   │   ├── database/           # IsarService (Singleton de conexión, transacciones de lectura/escritura)
│   │   ├── errors/             # Jerarquía sellada Failure (DatabaseFailure, CameraFailure, etc.) y Result<T> (Ok/Err)
│   │   ├── extensions/         # Extensiones sobre tipos primitivos (formato de moneda .toCop, .toSignedCop)
│   │   ├── gallery/            # Manejo de almacenamiento público y privado de comprobantes de pago
│   │   ├── notifications/      # NotificationService para alarmas locales de radar y transferencias
│   │   ├── router/             # AppRouter (GoRouter con ShellRoute, barra de navegación custom y animaciones)
│   │   ├── services/           # Servicios de utilidad (TableCounterService para numeración correlativa)
│   │   ├── settings/           # Providers de SharedPreferences (nombre del bar, parámetros financieros)
│   │   ├── theme/              # Paleta "Tiquete" (AppColors), dimensiones, estilos tipográficos y ThemeProvider
│   │   └── widgets/            # Componentes reutilizables (ReceiptPaper, DashedDivider, AnimatedAmount, AppToast)
│   └── features/               # Módulos de funcionalidad organizados por Clean Architecture
│       ├── base_management/    # Billetera del mesero: base inicial, aumentos/reducciones, deuda de licor y saldo disponible
│       ├── billing/            # Modelos de comprobantes de pago compartidos
│       ├── catalog/            # Catálogo estático auxiliar
│       ├── cierre/             # Cierre Blindado del turno: validación de blockers, cuadre de caja y guardado de ShiftSnapshot
│       ├── dashboard/          # Pantalla y lógica de legalización de transferencias en caja y enriquecimiento de billetera
│       ├── inicio/             # Tab 1: Home dashboard, accesos rápidos, métricas del turno y toggle de tema
│       ├── orders/             # Comandas por mesa: creación de ítems, repetición de rondas, cancelación y cálculo de facturas
│       ├── payments/           # Módulo de cobro: efectivo (con devuelta) y transferencias (cámara, visor y rotación)
│       ├── products/           # Gestión del menú, toggle de productos agotados y CRUD de categorías
│       ├── radar/              # KDS / pantalla de pedidos en cocina y barra (vista cronológica y agrupada por mesa)
│       ├── settings/           # Pantalla de configuración del bar y parámetros de turno
│       ├── shift_history/      # Historial de turnos cerrados y reportes gráficos de ganancias
│       └── tables/             # Gestión y cuadrícula de mesas activas, apodos y estados de cuenta
└── test/                       # Pruebas unitarias y de widgets
```

### Patrón Arquitectónico y Flujo de Datos
- **Clean Architecture por Capas y Features:**
  - `domain/`: Entidades puras e inmutables (`WalletSummary`, `BaseTransactionEntity`, `OrderItemEntity`, `TableSessionEntity`), contratos de repositorio (`IRepository`) y Casos de Uso independientes sin acoplamiento a Flutter ni a Isar.
  - `data/`: Modelos Isar con anotaciones (`@collection`, `@Index`), fuentes de datos locales y las implementaciones de los repositorios que mapean entre modelos de datos y entidades de dominio.
  - `presentation/`: Pantallas (`Screens`), componentes de UI (`Widgets`) y controladores de estado (`Providers` y `Notifiers` de Riverpod).
- **Flujo Contable Unidireccional y Reactivo:**
  1. Cada evento en la UI (ej. agregar un trago, cobrar una mesa, confirmar un pago en caja) ejecuta una llamada al repositorio correspondiente.
  2. El repositorio ejecuta una transacción atómica `IsarService.write((db) => ...)`.
  3. Las consultas reactivas de Isar (`.watchLazy()`) emiten en tiempo real a través de los `StreamProvider` de Riverpod.
  4. Los providers derivados como `enrichedWalletSummaryProvider` recalculan instantáneamente las fórmulas financieras sin necesidad de recargar la interfaz ni ejecutar peticiones manuales.

---

## 4. Capacidades Funcionales (Lo que SÍ hace)

### 1. Billetera y Contabilidad Estricta del Mesero (`base_management` y `dashboard`)
- Inicialización obligatoria de turno con base inicial (por defecto **$300.000 COP**, configurable desde ajustes).
- Registro auditado de incrementos manuales (**+$100.000 COP**) y reducciones con timestamp exacto.
- **Regla Especial de Licor:** Cuando se pide una botella de licor o descorche, su costo se carga inmediatamente a la **Deuda Total**, pero **no** disminuye el Saldo Disponible de la base del mesero.
- Opción de "Saldar / Pagar Botella" para botellas completadas directamente en barra o caja (operación *pass-through* que descuenta la deuda sin tocar el efectivo de la billetera).
- Fórmulas financieras automatizadas en tiempo real:
  - $\text{Capital Base} = \text{Base Inicial} + \sum(\text{Incrementos}) - \sum(\text{Reducciones})$
  - $\text{Deuda Total} = \text{Capital Base} + \sum(\text{Deuda por Licor})$
  - $\text{Saldo Disponible} = \text{Capital Base} + \sum(\text{Transferencias Legalizadas}) + \sum(\text{Cobros Efectivo}) - \sum(\text{Estándar Servidos})$
  - $\text{Ganancia Neta / Propinas} = \text{Efectivo Físico en Mano} - \text{Deuda Total} + \sum(\text{Propinas en Transferencias})$

### 2. Control Integral de Mesas (`tables`)
- Cuadrícula ágil de 2 columnas de mesas abiertas y con pago parcial.
- Numeración automática secuencial garantizada (`TableCounterService`), asegurando que nuevas mesas tomen números correlativos sin colisionar.
- Asignación y edición rápida de apodos privados (ej. "Mesa de cumpleaños", "Amigos de Pipe").
- Historial navegable de mesas cerradas con desglose del pedido final y código de verificación.

### 3. Comandas, Menú y Modos de Combinación (`orders` y `products`)
- Catálogo precargado de productos con 6 versiones de migraciones automáticas (`ProductRepositoryImpl`).
- Soporte para **productos combinables (Micheladas)**: al solicitar una Michelada, el mesero selecciona interactivamente la base requerida (catálogos de Cervezas o Sodas).
- Modificador de notas personalizadas por ítem (ej. "Sin hielo", "Vaso escarchado", "Con limón").
- Acción de "Repetir ronda" o duplicar ítems rápidamente.
- Cancelación con opción de deshacer y purga de cancelados.
- Visualización de la cuenta en formato tiquete térmico analógico con desglose por ítem y total a pagar.
- Pantalla de control de productos **Agotados** que bloquea instantáneamente la selección de ítems no disponibles en el bar.
- Gestor y CRUD de categorías con posibilidad de reordenar y renombrar globalmente.

### 4. KDS / El Radar de Pedidos (`radar`)
- Pantalla operativa para meseros y barras/cocinas.
- Dos modalidades de visualización:
  - **Cronológico:** Lista global ordenada por antigüedad de solicitud para priorizar órdenes atrasadas.
  - **Por Mesa:** Agrupado por mesa con botón rápido **"Entregar todo"**.
- Marcado de entrega mediante swipe lateral o botón táctil con retroalimentación háptica.
- Cronómetro y badge dinámico de minutos transcurridos por cada comanda.
- Insignia con contador en el icono de la barra de navegación que alerta de pedidos pendientes.

### 5. Facturación, Cobros y Comprobantes (`payments` y `billing`)
- Cobro total o cobro parcial dividido (selección individual de ítems o cantidades unitarias específicas de un ítem múltiple).
- **Pago en Efectivo:** Entrada numérica asistida con botones rápidos de billetes colombianos ($10k, $20k, $50k, $100k) y cálculo exacto de la devuelta/cambio a entregar.
- **Pago por Transferencia:**
  - Obligatoriedad de captura fotográfica mediante cámara del dispositivo o selección de galería.
  - Herramienta integrada de previsualización y **rotación de 90°** para asegurar legibilidad.
  - Selector de banco: **Nequi, Daviplata, Bancolombia, Dale, Otro**.
  - Generación algorítmica de código de verificación de 8 dígitos basado en SHA-256.
  - Copia dual del comprobante: privada de la app y pública en `Pictures/TheBase_Transferencias` vía canal nativo Android.
  - Captura suelta de comprobantes (fotos independientes no atadas a una mesa específica).
  - Galería visual interna de comprobantes almacenados con capacidad para compartir a través de WhatsApp u otras aplicaciones (`share_plus`).

### 6. Legalización en Caja (`dashboard`)
- Pantalla de dos pestañas: *Pendientes* y *Legalizadas*.
- Flujo de validación cruzada: El cajero o encargado coteja la transferencia recibida y el mesero presiona "Cobrado en Caja", inyectando de inmediato dicho monto al Saldo Disponible del mesero.

### 7. Cierre Blindado de Turno (`cierre`)
- Mecanismo algorítmico de auditoría final que **bloquea** el cierre de la jornada si:
  1. Existen pedidos pendientes de entrega en El Radar.
  2. Existen mesas activas abiertas o con saldo pendiente de pago.
  3. Existen transferencias registradas sin legalizar en caja.
- Ingreso del efectivo físico real contado por el mesero.
- Comparación automática contra la deuda total y cálculo transparente de la ganancia neta o descuadre.
- Al confirmar el cierre: se genera un `ShiftSnapshot` inmutable en el historial y se limpian atómicamente todas las colecciones operativas del turno (mesas, pedidos, pagos y transacciones de base), dejando intactos los productos y configuraciones.

### 8. Historial de Turnos y Reportes (`shift_history`)
- Lista histórica de todas las jornadas finalizadas.
- Vista detallada de cada turno cerrado en formato tiquete con todos los valores congelados.
- Pantalla de Reportes con métricas consolidadas (ingresos totales, ganancia promedio, mejor y peor turno, y tendencia cronológica de los últimos 14 turnos).

---

## 5. Límites, Pendientes y Deuda Técnica (Lo que NO hace todavía)

### Limitaciones de Arquitectura y Alcance
1. **Instalación Monousuario / Sin Sincronización Multi-terminal:**
   - La base de datos es exclusivamente local en el dispositivo. No existe replicación P2P, mesh WiFi ni sincronización en la nube entre múltiples dispositivos en tiempo real. Cada mesero opera su propia terminal independiente.
2. **Descarte de Integración con Supabase:**
   - En el código existen vestigios y campos reservados (`supabasePhotoUrl` en `PaymentReceipt`, `NetworkFailure` y `StorageFailure` en `failures.dart`). No se cuenta con el SDK de Supabase instalado ni con sincronización remota activa; la app se consolidó como 100% offline.
3. **Plataforma Objetivo Única (Android):**
   - Aunque el código es Flutter, la configuración nativa de íconos (`pubspec.yaml`), el canal nativo `MainActivity.kt` (`saveToGallery`), la gestión de barra de sistema transparente y los fixes contra bugs de rendering de Impeller en GPUs Xiaomi/MIUI (`_NoStretchScrollBehavior`) están diseñados y probados exclusivamente para **Android**.
4. **Pérdida de Desglose Histórico de Productos en Cierre:**
   - Al finalizar un turno, las colecciones `TableSession` y `OrderItem` se limpian completamente (`clear()`) para arrancar el siguiente turno en limpio. Por diseño, solo se preserva el `ShiftSnapshot` con los totales financieros. La pantalla de Reportes no puede desglosar qué productos individuales se vendieron en turnos anteriores.
5. **Capacidad de Almacenamiento en Disco para Fotos:**
   - Las capturas de comprobantes se guardan en el almacenamiento local del teléfono. Si el dispositivo se queda sin memoria interna, la operación fallará (la app maneja la excepción y anula la transacción atómica, pero requiere que el usuario limpie la carpeta periódicamente).

### Puntos Ciegos de Testing y Deuda Técnica
1. **Suite de Pruebas No Operativa:**
   - El archivo `test/widget_test.dart` mantiene el código autogenerado de prueba de humo de Flutter buscando `const MyApp()`. No compila con `TheBaseApp` y fallará al correr `flutter test`.
   - No existen pruebas unitarias para los casos de uso financieros (`WalletSummary`, `CierreRepositoryImpl`, etc.), ni pruebas de integración de base de datos Isar.

---

## 6. Reglas Estrictas para Asistentes de IA

### Convenciones de Código y Arquitectura
1. **Clean Architecture Estricta:**
   - Respetar el flujo de dependencias: `Presentation -> Domain <- Data`.
   - Los modelos de Isar residen en `data/models/`. Las entidades puras en `domain/entities/`.
   - **Prohibido:** Importar modelos de datos de Isar dentro de la capa `domain/` o en casos de uso. La conversión debe hacerse siempre en los repositorios de la capa `data/`.
2. **Gestión de Errores con `Result<T>`:**
   - Nunca lanzar excepciones no controladas a través de las capas. Utilizar la estructura sellada `Result<T>` (`Ok(value)` o `Err(Failure)`).
   - Tipar exhaustivamente los subtipos de `Failure` definidos en `lib/core/errors/failures.dart`.
3. **Manejo de Transacciones de Base de Datos:**
   - Cualquier escritura a la base de datos debe envolverse obligatoriamente en `IsarService.write((db) async { ... })`. Nunca intentar mutar colecciones fuera de una transacción.
   - En modelos con `autoIncrement`, no asignar IDs manualmente.
4. **Reglas Financieras Inmutables (No Modificar sin Aprobación):**
   - Todos los valores monetarios son **enteros en COP** (sin decimales ni floats). Usar siempre las extensiones `.toCop` y `.toSignedCop` para formateo visual.
   - La regla de licor: el licor solo incrementa la **Deuda**, nunca resta del **Saldo Disponible**.
   - Los blockers de Cierre Blindado no deben desactivarse ni flexibilizarse.
5. **Librerías y Enfoques Prohibidos:**
   - **PROHIBIDO:** Usar `google_fonts` descargando fuentes en runtime vía red. Todas las fuentes deben consumirse desde `assets/fonts/` (Nunito o Space Mono).
   - **PROHIBIDO:** Introducir dependencias de backend en la nube que rompan el principio de operación 100% desconectada de la red.
   - **PROHIBIDO:** Añadir efectos de `stretch-overscroll` que rompan el renderizado en GPUs Xiaomi/MIUI con Impeller. Conservar siempre `_NoStretchScrollBehavior`.
   - **PROHIBIDO:** Modificar la barra inferior de navegación para volverla opaca o alterar su comportamiento EdgeToEdge transparente.
6. **Nomenclatura y Tipado:**
   - Archivos y carpetas en `snake_case`.
   - Clases y tipos en `UpperCamelCase`.
   - Variables y métodos en `lowerCamelCase`.
   - Tipado explícito requerido en parámetros públicos y firmas de retorno; evitar `dynamic`.
   - Usar `final` y `const` de forma proactiva para optimizar el árbol de widgets.

