// // lib/data/services/auth_api.dart
// import 'http_client.dart';
// import 'auth_service.dart';
//
// class AuthApi {
//   Future<void> login({
//     required String username,
//     required String password,
//   }) async {
//     final map = await ApiClient.instance.postJson(
//       '/api/auth/login',
//       {'username': username, 'password': password},
//       includeAuth: false,
//     );
//     await AuthService.instance.signInPersist(map);
//   }
// }





// // lib/data/services/auth_api.dart
// import 'package:mobileApp/data/services/routes.dart';
//
// import 'http_client.dart';
// import 'auth_service.dart';
//
// class AuthApi {
//   AuthApi._();
//   static final AuthApi instance = AuthApi._();
//
//   /// Backend expects:
//   /// POST /{tenantId}/api/auth/login
//   /// Content-Type: application/json
//   /// { "email": "<email>", "password": "<password>" }
//   Future<void> login({required String email, required String password}) async {
//     // 1) Login
//     final json = await ApiClient.instance.postJson(
//       Routes.login,
//       body: {'email': email, 'password': password},
//     );
//     // print(Routes.login);
//     // token can be "accessToken" or "token"
//     final token  = (json['accessToken'] as String?) ?? (json['token'] as String?);
//     final refreshToken = json['refreshToken'] as String?;
//     final employeeName = (json['employeeName'] as String?) ?? (json['fullName'] as String?);
//
//     if (token == null || token.isEmpty) {
//       throw StateError('Login response missing token.');
//     }
//
//     // Store token (+ optional employeeId/employeeName if present)
//     AuthService.instance.applyLogin(
//       accessToken: token,
//       // employeeId: employeeId ?? '', // may be empty if backend doesn’t return it
//       refreshToken: refreshToken,
//       employeeName: employeeName,
//     );
//
//     // 2) Fetch /me to resolve employeeId (and canonical name)
//     try {
//       final me = await ApiClient.instance.getJson(Routes.me);
//       final empId = (me['employeeId'] as String?) ?? (me['empId'] as String?) ?? (me['id'] as String?);
//       final name  = (me['employeeName'] as String?) ?? (me['fullName'] as String?) ?? (me['name'] as String?);
//       AuthService.instance.updateProfile(employeeId: empId, employeeName: name);
//     } catch (_) {
//       // If /me isn’t available now, dashboard calls that require employeeId will throw.
//       // Ask backend to add it OR add a “employeeId” field to login response.
//     }
//   }
// }



// lib/data/services/auth_api.dart
import 'dart:convert';

import '././routes.dart';

import 'employee_service.dart';
import './http_client.dart';
import 'auth_service.dart';
import 'dart:developer'; // Added for proper logging


// Lightweight response for token endpoints
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn; // seconds

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    String? _pickStr(Iterable<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    int? _pickInt(Iterable<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is num) return v.toInt();
      }
      return null;
    }

    final access = _pickStr(['accessToken', 'access_token', 'token']) ?? '';
    return AuthResponse(
      accessToken: access,
      refreshToken: _pickStr(['refreshToken', 'refresh_token']),
      expiresIn: _pickInt(['expiresIn', 'expires_in']),
    );
  }
}

Map<String, dynamic> _decodeJwtPayload(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) {
    throw FormatException('Invalid JWT');
  }
  String _normalize(String s) {
    // base64url decode requires padding
    final r = s.length % 4;
    if (r == 2) return '$s==';
    if (r == 3) return '$s=';
    if (r == 0) return s;
    throw FormatException('Invalid base64url');
  }
  final payload = utf8.decode(base64Url.decode(_normalize(parts[1])));
  final Map<String, dynamic> json = jsonDecode(payload) as Map<String, dynamic>;
  return json;
}

class AuthApi {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  /// Backend expects:
  /// POST /{tenantId}/api/auth/login
  /// Content-Type: application/json
  /// { "email": "<email>", "password": "<password>" }
  // Future<void> login({required String email, required String password}) async {
  //   // 1) Login
  //   final json = await ApiClient.instance.postJson(
  //     Routes.login,
  //     body: {'email': email, 'password': password},
  //   );
  //
  //   // Extract tokens and basic info
  //   final token  = (json['accessToken'] as String?) ?? (json['token'] as String?);
  //   final refreshToken = (json['refreshToken'] as String?);
  //   final employeeName = (json['employeeName'] as String?) ?? (json['fullName'] as String?);
  //
  //   // Check if employee ID is provided directly in the login response
  //   final employeeIdFromLogin = (json['employeeId'] as String?) ?? (json['empId'] as String?) ?? (json['id'] as String?);
  //
  //   if (token == null || token.isEmpty) {
  //     throw StateError('Login response missing token.');
  //   }
  //
  //   // Store token (+ optional employeeId/employeeName).
  //   AuthService.instance.applyLogin(
  //     accessToken: token,
  //     employeeId: employeeIdFromLogin ?? '',
  //     refreshToken: refreshToken,
  //     employeeName: employeeName,
  //   );
  //
  //   // Placeholder for any error message from the /me endpoint
  //   String? meErrorMessage;
  //
  //   // 2) Fetch /me to resolve the definitive employeeId (and canonical name)
  //   try {
  //     final me = await ApiClient.instance.getJson(Routes.me);
  //     final empId = (me['employeeId'] as String?) ?? (me['empId'] as String?) ?? (me['id'] as String?);
  //     final name  = (me['employeeName'] as String?) ?? (me['fullName'] as String?) ?? (me['name'] as String?);
  //
  //     AuthService.instance.updateProfile(employeeId: empId, employeeName: name);
  //   } on ApiException catch (e) { // <<< CATCHES THE STRUCTURED API ERROR
  //     // Case A: /me call failed (e.g., 401 Unauthorized, 404 Not Found).
  //     // We prioritize reporting the HTTP status for easy debugging.
  //     meErrorMessage = 'Profile fetch failed. Status ${e.statusCode} on ${e.path}';
  //     log('Warning: Failed to fetch /me endpoint: $meErrorMessage. Body: ${e.body}', name: 'AuthApi');
  //   } catch (e) {
  //     // Catch any other exceptions (e.g., JSON decoding error)
  //     meErrorMessage = 'Non-HTTP error during profile fetch: $e';
  //     log('Warning: Non-API error fetching /me: $meErrorMessage', name: 'AuthApi');
  //   }
  //
  //   // CRITICAL CHECK: Ensure we have a valid employee ID.
  //   if (AuthService.instance.employeeId == null || AuthService.instance.employeeId!.isEmpty) {
  //
  //     String message;
  //
  //     if (meErrorMessage != null) {
  //       // Report the captured API error clearly.
  //       message = 'Authentication successful, but required Employee ID could not be resolved. $meErrorMessage';
  //     } else if (employeeIdFromLogin == null) {
  //       // This means /me succeeded (HTTP 200) but didn't contain the ID field.
  //       message = 'Authentication successful, but the profile endpoint (${Routes.me}) succeeded without returning a valid Employee ID field.';
  //     } else {
  //       message = 'Login successful, but a valid Employee ID could not be set.';
  //     }
  //
  //     log('Final Login Failure: $message', name: 'AuthApi');
  //     throw StateError(message);
  //   }
  // }

  Future<void> login({required String email, required String password}) async {
    // 1) authenticate
    final loginJson = await ApiClient.instance.postJson(
      Routes.login,
      body: {'email': email, 'password': password},
    );

    // tokens from body
    final token        = (loginJson['accessToken'] as String?) ?? (loginJson['token'] as String?);
    final refreshToken =  loginJson['refreshToken'] as String?;

    if (token == null || token.isEmpty) {
      throw StateError('Authentication succeeded but response has no access token.');
    }

    // 2) claims from JWT (this is where employeeId lives for you)
    final claims = _decodeJwtPayload(token);
    final employeeIdFromJwt = (claims['employeeId']?.toString());
    final nameFromJwt       = (claims['fullName'] as String?);
    final tenantFromJwt     = (claims['tenantId'] as String?);
    final expEpochSeconds   = (claims['exp'] is num) ? (claims['exp'] as num).toInt() : null;

    // 3) also pick any explicit fields in body if present (fallback)
    final employeeIdFromBody = (loginJson['employeeId'] as String?) ??
        (loginJson['empId'] as String?) ??
        (loginJson['id'] as String?);
    final employeeNameFromBody = (loginJson['employeeName'] as String?) ??
        (loginJson['fullName'] as String?) ??
        (loginJson['name'] as String?);

    final employeeId   = employeeIdFromBody ?? employeeIdFromJwt ?? '';
    final employeeName = employeeNameFromBody ?? nameFromJwt;

    // 4) apply & persist session (now with real employeeId)
    AuthService.instance.applyLogin(
      accessToken: token,
      refreshToken: refreshToken,
      email: email,
      employeeId: employeeId,
      employeeName: employeeName,
    );

    // 5) persist expiry from JWT (so silent refresh triggers on time)
    if (expEpochSeconds != null) {
      await AuthService.instance.updateExpiryEpoch(expEpochSeconds);
    }

    // (Optional sanity): If tenant was not set earlier, you could store tenantFromJwt in TenantService.
    // We don't auto-change it here to avoid conflicting with your chosen tenant in UI.
  }




  /// POST /{tenant}/api/auth/refresh  { "refreshToken": "<token>" }
  /// Returns new access token (and optionally a new refresh token + expiry).
  Future<AuthResponse?> refresh({required String refreshToken}) async {
    // NOTE: If your ApiClient auto-attaches Authorization, that’s fine.
    // Refresh endpoints normally ignore an expired bearer.
    final json = await ApiClient.instance.postJson(
      Routes.refresh,
      body: {'refreshToken': refreshToken},
    );

    // Map to a typed response; return null if no usable access token
    final res = AuthResponse.fromJson(json);
    if (res.accessToken.isEmpty) return null;
    return res;
  }

}