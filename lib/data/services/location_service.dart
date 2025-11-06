// lib/data/services/location_service.dart

import 'dart:async'; // ⭐ Required for Duration
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import 'package:kiosk/data/services/routes.dart';
import '../models/employee_location_model.dart';
import 'auth_service.dart';
import 'http_client.dart';// ⭐ FIX 1: ADD THIS IMPORT
import 'tenant_service.dart'; // Import TenantService

// ⭐ NEW CONSTANT: Defines the interval for background location sending
const Duration LOCATION_TRACKING_INTERVAL = Duration(seconds: 120); // 2 minutes

/// Defines the outcome of the location check and API call.
enum LocationCheckStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  apiFailure,
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();


  // ⭐ Core implementation: Handles the actual API call (must be updated to receive the DTO)
  // We'll rename the generic method for clarity and create new methods below.

  // 1. CLOCK IN (START SESSION)
  Future<String> startSession(double lat, double lng, String capturedAt) async {
    // ApiClient's internal _headers helper automatically adds
    // the X-Tenant-Id from TenantService.instance.tenantId.
    final body = {
      "lat": lat,
      "lng": lng,
      "capturedAt": capturedAt
    };

    // This calls the DTO in:
    // .../dto/ClockInRequest.java
    final response = await ApiClient.instance.postJson(
      '/api/tracking/clock-in',
      body: body,
    );

    // This matches the DTO in:
    // .../dto/ClockInResponse.java
    final sessionId = response['sessionId']?.toString();
    if (sessionId == null) {
      throw Exception('Server did not return a session ID on Clock-In.');
    }
    return sessionId;
  }

  // 2. PERIODIC PING / POINT
  Future<void> sendTrackingPoint(String sessionId, double lat, double lng, String capturedAt, int seq) async {
    final body = {
      // Backend DTOs expect sessionId as a number (Long)
      "sessionId": int.tryParse(sessionId) ?? 0,
      "lat": lat,
      "lng": lng,
      "capturedAt": capturedAt,
      "seq": seq,
    };

    // This calls the DTO in:
    // .../dto/PointRequest.java
    await ApiClient.instance.postJson(
      '/api/tracking/point',
      body: body,
    );
  }

  // 3. CLOCK OUT (CLOSE SESSION)
  Future<void> endSession(String sessionId, int seq) async {
    final body = {
      "sessionId": int.tryParse(sessionId) ?? 0,
      "seq": seq,
    };

    // This calls the DTO in:
    // .../dto/CloseRequest.java
    await ApiClient.instance.postJson(
      '/api/tracking/clock-out',
      body: body,
    );
  }

  // 4. [NEW] GET LIVE SESSION (for Warm-Start)
  // This method is required by the new my_day_screen logic.
  Future<Map<String, dynamic>?> getLive() async {
    try {
      // We will add this /live endpoint to the backend in Step 2.
      final resp = await ApiClient.instance.getJson(
        '/api/tracking/live',
      );
      if (resp.isEmpty || resp['sessionId'] == null) {
        return null;
      }
      return resp;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null; // 404 means no open session, which is fine.
      }
      rethrow; // Re-throw other API errors
    } catch (e) {
      debugPrint('getLive error: $e');
      return null;
    }
  }
  // ⭐ UPDATED: Method now requires punchType
  /// This function handles a single location check, permission check,
  /// and API transmission, now including optional session ID.
  Future<LocationCheckStatus> checkAndTrackLocation(
      String punchType,
      {String? sessionId} // ⭐ NEW: Optional named parameter for session ID
      ) async {

    // This old logic is not compatible with your new backend.
    debugPrint('WARNING: DEPRECATED location_service method "checkAndTrackLocation" was called.');
    // ⭐ FIX 2: GET EMPLOYEE ID BEFORE CONTINUING
    final employeeId = AuthService.instance.employeeId;
    if (employeeId == null || employeeId.isEmpty) {
      debugPrint('Location tracking failed: Employee ID is missing. User may be logged out.');
      return LocationCheckStatus.apiFailure;
    }
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled on the device
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationCheckStatus.serviceDisabled;
    }

    // 2. Check and request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission only if it was denied previously (not denied forever)
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationCheckStatus.permissionDenied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationCheckStatus.permissionDeniedForever;
    }

    // Check again after request, if still denied, return denied status
    if (permission == LocationPermission.denied) {
      return LocationCheckStatus.permissionDenied;
    }


    // 3. Get the current position and send data to the backend API
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final model = EmployeeLocationModel.fromPosition(
        employeeId,
        position,
        punchType,
        sessionId: sessionId,
      );

      // This is the WRONG endpoint.
      await ApiClient.instance.postJson(
        Routes.trackLocation, // This is not /api/tracking/point
        body: model.toJson(),
      );

      return LocationCheckStatus.success;

    } on Exception catch (e) {
      if (e is ApiException) {
        debugPrint('Location API call failed with status: ${e.statusCode} and body: ${e.body}');
      } else {
        debugPrint('Error getting location or sending data: $e');
      }
      return LocationCheckStatus.apiFailure;
    }
  }
}