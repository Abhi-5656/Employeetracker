// lib/data/models/employee_location_model.dart

import 'package:geolocator/geolocator.dart';

class EmployeeLocationModel {
  // Keep this field for internal logic within LocationService
  final String employeeId;
  final double latitude;
  final double longitude;
  final String timestamp;
  // ⭐ NEW FIELD: To specify the type of punch
  final String punchType;
  // ⭐ NEW FIELD: Session ID (optional for initial punch, mandatory for periodic pings)
  final String? sessionId;

  EmployeeLocationModel({
    required this.employeeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.punchType, // Include new field
    this.sessionId, // Mark as optional
  });

  /// Converts the object to the required JSON format for the API.
  /// ⭐ FIX: Only send fields the server expects from the client (latitude, longitude, timestamp).
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'punchType': punchType,
    };
    // Include sessionId only if it exists (for tracking pings)
    if (sessionId != null) {
      json['sessionId'] = sessionId;
    }
    return json;

  }

  /// Factory method to create the model directly from a geolocator Position.
  factory EmployeeLocationModel.fromPosition(
      String employeeId,
      Position position,
      String punchType,
      {String? sessionId} // Optional named parameter
      ) {
    // ⭐ FIX: Use a clean toUtc().toIso8601String() call.
    // This standard format (e.g., 2025-10-28T10:30:00.000Z) is what Java Instant expects.
    final timestamp = position.timestamp.toUtc().toIso8601String();

    return EmployeeLocationModel(
      employeeId: employeeId,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: timestamp,
      punchType: punchType, // Pass to constructor
      sessionId: sessionId,
    );
  }
}