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
    // final employeeId = AuthService.instance.employeeId;
    // Note: ApiClient's internal _headers helper automatically adds
    // the X-Tenant-Id from TenantService.instance.tenantId.
    // No need to pass it manually.

    final body = {
      "lat": lat,
      "lng": lng,
      "capturedAt": capturedAt
    };

    // ⭐ NEW ROUTE: Using the assumed new Clock-In endpoint
    final response = await ApiClient.instance.postJson(
      '/api/tracking/clock-in', // Assuming the path defined in backend plan
      body: body,
    );

    // Server must return { sessionId: 12345, status: "OPEN" }
    final sessionId = response['sessionId']?.toString();
    if (sessionId == null) {
      throw Exception('Server did not return a session ID on Clock-In.');
    }
    return sessionId;
  }

  // 2. PERIODIC PING / POINT
  Future<void> sendTrackingPoint(String sessionId, double lat, double lng, String capturedAt, int seq) async {
    final body = {
      // Backend expects sessionId as a number (Long)
      "sessionId": int.tryParse(sessionId) ?? 0,
      "lat": lat,
      "lng": lng,
      "capturedAt": capturedAt,
      "seq": seq,
    };

    // ⭐ NEW ROUTE: Using the assumed new Tracking Point endpoint
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

    // ⭐ NEW ROUTE: Using the assumed new Clock-Out endpoint
    await ApiClient.instance.postJson(
      '/api/tracking/clock-out',
      body: body,
    );
  }

  // 4. [R3] GET LIVE SESSION (for Warm-Start)
  Future<Map<String, dynamic>?> getLive() async {
    // We use getJson which automatically adds Auth and X-Tenant-Id
    try {
      final resp = await ApiClient.instance.getJson(
        '/api/tracking/live',
      );
      // If server returns 200 OK with empty body or no sessionId, treat as no session
      if (resp.isEmpty || resp['sessionId'] == null) {
        return null;
      }
      return resp;
    } on ApiException catch (e) {
      // Handle 404 (No Open Session) gracefully
      if (e.statusCode == 404) {
        return null;
      }
      // Re-throw other API errors
      rethrow;
    } catch (e) {
      debugPrint('getLive error: $e');
      return null; // Treat other errors as no-session
    }
  }
  // ⭐ UPDATED: Method now requires punchType
  /// This function handles a single location check, permission check,
  /// and API transmission, now including optional session ID.
  Future<LocationCheckStatus> checkAndTrackLocation(
      String punchType,
      {String? sessionId} // ⭐ NEW: Optional named parameter for session ID
      ) async {
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

      // ⭐ UPDATED: Pass punchType AND sessionId to the factory constructor
      final model = EmployeeLocationModel.fromPosition(
        employeeId,
        position,
        punchType,
        sessionId: sessionId, // Pass the ID
      );

      // Call the API to track the location coordinates
      await ApiClient.instance.postJson(
        Routes.trackLocation,
        body: model.toJson(),
      );

      // If execution reaches here, the API call was successful (2xx status)
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