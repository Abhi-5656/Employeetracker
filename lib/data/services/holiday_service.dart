// data/services/holiday_service.dart

// data/services/holiday_service.dart

// data/services/holiday_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'http_client.dart' show ApiClient;
import 'routes.dart';
import '../models/holiday_model.dart';

class HolidayService {
  HolidayService._();
  static final HolidayService instance = HolidayService._();

  /// Fetch holidays for an employee.
  ///
  /// ⚠ The backend for this call returns:
  /// {
  ///   "holidays": [ { "holidayName": "...", "startDate": "YYYY-MM-DD", "endDate": "...", "holidayType": "...", ... }, ... ],
  ///   "employeeId": "1032"
  /// }
  ///
  /// We normalize each item into a map your `Holiday.fromJson` already understands:
  /// { "name": "...", "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD", "type": "..." }
  ///
  /// `year` is optional/ignored here (kept for compatibility with callers).
  Future<List<Holiday>> fetchEmployeeHolidays({
    required String employeeId,
    int? year, // ignored by this endpoint but kept for signature compatibility
  }) async {
    // Build the path using the new route helper
    final path = Routes.employeeHolidaysV2(employeeId);

    // Hit API using your ApiClient with auto-refresh + tenant handling
    final Map<String, dynamic> body = await ApiClient.instance.getJson(path);

    // Extract the list from "holidays"
    final raw = body['holidays'];
    if (raw == null) {
      // Treat missing list as "no holidays" instead of throwing
      return const <Holiday>[];
    }
    if (raw is! List) {
      if (kDebugMode) {
        debugPrint('HolidayService: "holidays" is not a List. Body: $body');
      }
      return const <Holiday>[];
    }

    final out = <Holiday>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;

      // Normalize keys to what your model expects
      final normalized = <String, dynamic>{
        // model expects "name"
        'name': item['holidayName'] ?? item['name'] ?? '',
        // model expects "type" (optional)
        'type': item['holidayType'] ?? item['type'],
        // model expects "startDate"/"endDate" in ISO; API already gives "YYYY-MM-DD"
        'startDate': item['startDate'],
        'endDate': item['endDate'],
        // keep original fields too, in case your fromJson reads them
        ...item,
      };

      try {
        out.add(Holiday.fromJson(normalized));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('HolidayService: failed to parse one holiday: $e | $item');
        }
      }
    }
    return out;
  }
}


















// import 'dart:convert';
// import 'package:flutter/foundation.dart';
//
// import '../../data/models/holiday_model.dart';
// import '../services/http_client.dart' show ApiClient;
// import '../services/routes.dart';
//
// class HolidayService {
//   HolidayService._();
//   static final HolidayService instance = HolidayService._();
//
//   /// GET /api/v1/employees/{employeeId}/holidays?year=YYYY
//   Future<List<Holiday>> fetchEmployeeHolidays({
//     required String employeeId,
//     required int year,
//   }) async {
//     // Build the path using your centralized routes helper
//     final String path = Routes.employeeHolidays(employeeId, year);
//
//     // Try the "array" route first (many APIs return a list directly)
//     try {
//       final List<dynamic> raw = await ApiClient.instance.getList(path);
//       return _parseHolidayList(raw);
//     } catch (errFirst) {
//       // If it wasn't a list, try as an object with a list inside ("data", "items", etc.)
//       try {
//         final Map<String, dynamic> obj = await ApiClient.instance.getJson(path);
//         final dynamic inner =
//             obj['data'] ?? obj['items'] ?? obj['content'] ?? obj['holidays'] ?? obj['rows'] ?? obj['result'];
//
//         if (inner is List) {
//           return _parseHolidayList(inner);
//         }
//
//         // Some servers (rarely) put JSON in a string field
//         if (inner is String) {
//           try {
//             final decoded = jsonDecode(inner);
//             if (decoded is List) {
//               return _parseHolidayList(decoded);
//             }
//           } catch (_) {
//             // fall through
//           }
//         }
//
//         // Nothing recognizable — return empty list rather than throw
//         if (kDebugMode) {
//           debugPrint('HolidayService: unrecognized holidays payload shape: $obj');
//         }
//         return const <Holiday>[];
//       } catch (errSecond) {
//         // Re-throw the original, more relevant error
//         rethrow;
//       }
//     }
//   }
//
//   List<Holiday> _parseHolidayList(List<dynamic> raw) {
//     final out = <Holiday>[];
//     for (final e in raw) {
//       if (e is Map<String, dynamic>) {
//         try {
//           out.add(Holiday.fromJson(e));
//         } catch (err) {
//           if (kDebugMode) {
//             debugPrint('Holiday parse skipped: $err | $e');
//           }
//         }
//       }
//     }
//     return out;
//   }
// }

















// import 'package:flutter/foundation.dart';
//
// import '../models/holiday_model.dart';
// import 'http_client.dart';   // ApiClient with getList/getJson + auto-refresh
// import 'routes.dart';        // Routes.employeeHolidays
//
// class HolidayService {
//   HolidayService._();
//   static final HolidayService instance = HolidayService._();
//
//   /// GET /api/v1/employees/{employeeId}/holidays?year=YYYY
//   Future<List<Holiday>> fetchEmployeeHolidays({
//     required String employeeId,
//     required int year,
//   }) async {
//     final path = Routes.employeeHolidays(employeeId, year);
//
//     // 1) Prefer a raw JSON array
//     try {
//       final list = await ApiClient.instance.getList(path); // expects List<dynamic>
//       return _parseList(list);
//     } on TypeError catch (_) {
//       // JSON was not a List — likely a wrapper object. Fall back.
//       if (kDebugMode) {
//         debugPrint('HolidayService: response is not a List; trying getJson wrapper parse…');
//       }
//     } on Exception catch (e) {
//       // If it's an HTTP error, let it bubble unless wrapper succeeds below.
//       // We'll try wrapper path only for non-HTTP shape mismatches.
//       if (kDebugMode) debugPrint('HolidayService: getList failed: $e; attempting wrapper parse…');
//     }
//
//     // 2) Wrapper payloads: { data: [...] } or { content: [...] } or { items: [...] }
//     final obj = await ApiClient.instance.getJson(path); // expects Map<String, dynamic>
//     final raw = (obj['data'] ?? obj['content'] ?? obj['items']);
//     if (raw is List) {
//       return _parseList(raw);
//     }
//
//     // Nothing usable
//     return const <Holiday>[];
//   }
//
//   List<Holiday> _parseList(List<dynamic> raw) {
//     final out = <Holiday>[];
//     for (final e in raw) {
//       if (e is Map<String, dynamic>) {
//         try {
//           out.add(Holiday.fromJson(e));
//         } catch (err) {
//           if (kDebugMode) {
//             debugPrint('Holiday parse skipped: $err | $e');
//           }
//         }
//       }
//     }
//     return out;
//   }
// }
