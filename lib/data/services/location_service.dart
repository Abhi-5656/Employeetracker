// lib/data/services/location_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🟢 FIX 1: Import Environment and TenantService
import '../../app/config/environment.dart';
import 'tenant_service.dart';

import 'http_client.dart';
import 'auth_service.dart';

// Tracking interval set to 1 minute
const Duration LOCATION_TRACKING_INTERVAL = Duration(seconds: 30);
const String NOTIFICATION_CHANNEL_ID = 'my_foreground';
const int NOTIFICATION_ID = 888;

// ---------------------------------------------------------------------------
//  BACKGROUND ENTRY POINT
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Environment for background isolate
  const environment = String.fromEnvironment('FLAVOR', defaultValue: Environment.dev);
  Environment().init(environment);

  // Managers for background state
  Timer? _timer;
  String? _sessionId;
  int _seq = 0;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stop_service').listen((event) {
    _timer?.cancel();
    service.stopSelf();
  });

  // Listen for the start command from the UI
  service.on('start_tracking').listen((event) {
    if (event == null) return;
    _sessionId = event['sessionId'] as String?;
    final token = event['token'] as String?;

    // 🟢 FIX 2: Get Tenant ID from event
    final tenantId = event['tenantId'] as String?;

    // Inject the token for the background isolate
    if (token != null) {
      AuthService.instance.setTokenManual(token);
    }

    // 🟢 FIX 3: Inject Tenant ID manually
    if (tenantId != null) {
      TenantService.instance.setTenantManual(tenantId);
    }

    // Start the periodic timer
    _timer?.cancel();
    _timer = Timer.periodic(LOCATION_TRACKING_INTERVAL, (timer) async {
      if (_sessionId == null) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );

        _seq++;
        final capturedAt = DateTime.now().toUtc().toIso8601String();

        // DIRECT SEND TO ENDPOINT
        final body = {
          "sessionId": int.tryParse(_sessionId!) ?? 0,
          "lat": position.latitude,
          "lng": position.longitude,
          "capturedAt": capturedAt,
          "seq": _seq,
        };

        await ApiClient.instance.postJson('/api/tracking/point', body: body);

        // Update Notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "WorkForce Active",
            content: "Tracking active. Points sent: $_seq",
          );
        }
        debugPrint("Background point sent: $_seq");

      } catch (e) {
        debugPrint("Background tracking error: $e");
      }
    });
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

// ---------------------------------------------------------------------------
//  MAIN SERVICE CLASS
// ---------------------------------------------------------------------------

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      NOTIFICATION_CHANNEL_ID,
      'Location Tracking',
      description: 'This channel is used for location tracking service',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NOTIFICATION_CHANNEL_ID,
        initialNotificationTitle: 'WorkForce Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: NOTIFICATION_ID,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<String> startSession(double lat, double lng, String capturedAt) async {
    // 1. Call Tracking API
    // (The Backend now AUTOMATICALLY creates the timesheet punch)
    final body = {"lat": lat, "lng": lng, "capturedAt": capturedAt};

    final response = await ApiClient.instance.postJson('/api/tracking/clock-in', body: body);
    final sessionId = response['sessionId']?.toString();
    if (sessionId == null) throw Exception('No session ID returned');

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }

    // 🟢 FIX 4: Pass TenantID to the background service
    service.invoke('start_tracking', {
      'sessionId': sessionId,
      'token': AuthService.instance.token,
      'tenantId': TenantService.instance.tenantId, // <--- CRITICAL
    });

    return sessionId;
  }

  Future<void> endSession(String sessionId, int seq) async {
    final body = {"sessionId": int.tryParse(sessionId) ?? 0, "seq": seq};
    try {
      await ApiClient.instance.postJson('/api/tracking/clock-out', body: body);
    } catch (e) {
      debugPrint("Error closing session: $e");
    }

    final service = FlutterBackgroundService();
    service.invoke('stop_service');
  }

  Future<Map<String, dynamic>?> getLive() async {
    try {
      final resp = await ApiClient.instance.getJson('/api/tracking/live');
      if (resp.isNotEmpty && resp['sessionId'] != null) {
        final service = FlutterBackgroundService();
        if (!await service.isRunning()) {
          await service.startService();
        }
        // Warm Start: Pass data again to ensure service has context
        service.invoke('start_tracking', {
          'sessionId': resp['sessionId'].toString(),
          'token': AuthService.instance.token,
          'tenantId': TenantService.instance.tenantId, // <--- CRITICAL
        });
        return resp;
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      return null;
    }
  }

  Future<void> sendTrackingPoint(String sessionId, double lat, double lng, String capturedAt, int seq) async {
    final body = {
      "sessionId": int.tryParse(sessionId) ?? 0,
      "lat": lat,
      "lng": lng,
      "capturedAt": capturedAt,
      "seq": seq,
    };
    await ApiClient.instance.postJson('/api/tracking/point', body: body);
  }
}