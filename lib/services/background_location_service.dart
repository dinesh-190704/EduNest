import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences.dart';

class BackgroundLocationService {
  static const String _driverIdKey = 'driver_id';
  static FlutterBackgroundService? _instance;
  static const String _notificationChannelId = 'bus_tracking_service';
  static const String _notificationTitle = 'Bus Tracking Active';
  static const String _notificationDescription = 'Your location is being shared with students';

  static Future<void> initialize() async {
    _instance = FlutterBackgroundService();

    await _instance!.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: _notificationTitle,
        initialNotificationContent: _notificationDescription,
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Get driver ID from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString(_driverIdKey);

    if (driverId == null) {
      service.stopSelf();
      return;
    }

    // Initialize location tracking
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            // Send location update to main isolate
            service.invoke(
              'location',
              {
                'driverId': driverId,
                'latitude': position.latitude,
                'longitude': position.longitude,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            print('Error getting location: $e');
          }
        }
      }
    });
  }

  static Future<void> startService(String driverId) async {
    // Save driver ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverIdKey, driverId);

    // Start the service
    await _instance?.startService();
  }

  static Future<void> stopService() async {
    // Clear driver ID from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverIdKey);

    // Stop the service
    await _instance?.invoke('stopService');
  }

  static bool isRunning() {
    return _instance?.isRunning() ?? false;
  }

  // Initialize notifications
  static Future<void> initializeNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
}
