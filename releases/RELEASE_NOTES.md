# The Base v1.14.0

## 🚀 Novedades y Mejoras
* **Modo Oscuro (Carbon Contrast):** Nuevo modo nocturno de alto contraste para operar cómodamente de noche. Actívalo directamente con el icono del sol/luna en la cabecera de la pantalla de inicio.
* **Bloqueo Estricto de Turno:** La aplicación ya no permite navegar ni abrir mesas o pedidos nuevos hasta que no se inicialice un turno de forma explícita.
* **Indicador Consolidado de Deuda:** Agregamos una tarjeta en la pestaña de mesas con el "Total en Mesas", permitiéndote ver en tiempo real la suma total de lo que falta por cobrar.
* **Fórmula Financiera Corregida:** El cálculo del "Saldo Disponible" se ajustó para reflejar estrictamente la salida de productos estándar despachados.
* **Extinción del Abono Libre:** El flujo de cobros es ahora atómico (todo o nada, por producto o total). Se eliminó la opción de introducir un monto libre para evitar descuadres en caja.

## 🛠 Fixes Internos
* Refactorización de `AppTheme` y `AppColors` para soportar `ThemeMode` reactivo.
* Deprecaciones de la UI solventadas internamente.
