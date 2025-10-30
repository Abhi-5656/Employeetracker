// lib/data/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import 'package:kiosk/data/services/routes.dart';
import '../models/employee_location_model.dart';
import 'auth_service.dart';
import 'http_client.dart';// ⭐ FIX 1: ADD THIS IMPORT


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

  /// Orchestrates the location check, permission request, and API call.
  ///
  /// This method performs all the necessary checks and only returns
  /// LocationCheckStatus.success if location data is successfully obtained
  /// AND successfully sent to the backend.
  // ⭐ UPDATED: Method now requires punchType
  Future<LocationCheckStatus> checkAndTrackLocation(String punchType) async {
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

      // ⭐ UPDATED: Pass punchType to the factory constructor
      final model = EmployeeLocationModel.fromPosition(employeeId, position, punchType);

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