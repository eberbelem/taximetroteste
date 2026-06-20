import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundService {
  static const String _channelId = 'taximetro_channel';
  static const String _channelName = 'Taxímetro';
  static const String _channelDescription =
      'Notificação persistente do taxímetro em execução';
  static const int _notificationId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Taxímetro Digital',
        initialNotificationContent: '⏸ Aguardando corrida',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((data) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((data) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((data) {
      service.stopSelf();
    });

    service.on('updateNotification').listen((data) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: data?['title'] as String? ?? 'Taxímetro',
          content: data?['content'] as String? ?? '',
        );
      }
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }

  static Future<void> iniciar() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> parar() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static void atualizarNotificacao({
    required String titulo,
    required String conteudo,
  }) {
    final service = FlutterBackgroundService();
    service.invoke('updateNotification', {
      'title': titulo,
      'content': conteudo,
    });
  }
}
