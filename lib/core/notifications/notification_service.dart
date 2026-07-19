import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Singleton wrapper around flutter_local_notifications.
///
/// Handles two alert types:
///   • Radar alert — fires when pending-order count crosses the threshold.
///   • Transfer alert — fires when unlegalized transfers go from 0 to >0.
///
/// Periodic reminders are driven by the [_NotificationListenerWidget] timer
/// (defined in main.dart) and call [showRadarAlert] / [showTransferAlert]
/// directly.
final class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'thebase_alerts';
  static const _channelName = 'Alertas The Base';
  static const _channelDesc =
      'Recordatorios de pedidos pendientes y transferencias por legalizar';

  static const _idRadar = 1;
  static const _idTransfer = 2;

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    // Create the notification channel (required Android 8+).
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request POST_NOTIFICATIONS permission (Android 13+).
    await Permission.notification.request();
  }

  static Future<void> showRadarAlert(int count) async {
    await _plugin.show(
      _idRadar,
      'Pedidos sin entregar',
      '$count pedido${count == 1 ? '' : 's'} esperando entrega',
      _details(),
    );
  }

  static Future<void> showTransferAlert(int count) async {
    await _plugin.show(
      _idTransfer,
      'Transferencias por legalizar',
      '$count transferencia${count == 1 ? '' : 's'} sin confirmar en caja',
      // Persistente (no se puede deslizar): solo se quita cuando el estado
      // cambia y se llama cancelTransferAlert().
      _details(ongoing: true),
    );
  }

  /// Quita la notificación de transferencias (cuando ya no hay pendientes).
  static Future<void> cancelTransferAlert() async {
    await _plugin.cancel(_idTransfer);
  }

  /// Quita la notificación de radar (cuando ya no hay pendientes).
  static Future<void> cancelRadarAlert() async {
    await _plugin.cancel(_idRadar);
  }

  static NotificationDetails _details({bool ongoing = false}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        ongoing: ongoing,
        autoCancel: !ongoing,
      ),
    );
  }
}
