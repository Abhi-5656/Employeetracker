// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// //
// // import 'package:http/http.dart' as http;
// //
// // import 'tenant_service.dart';
// // import 'auth_service.dart';
// //
// // /// Global API client:
// // /// - Base host: ALB by default (can be overridden via --dart-define=API_HOST=...).
// // /// - Tenant in URL path: {host}/{tenant}/{path}
// // /// - Adds Authorization: Bearer <accessToken> (when available).
// // /// - One-time token refresh on 401 then retries the original request.
// // class ApiClient {
// //   ApiClient._();
// //   static final ApiClient instance = ApiClient._();
// //
// //   String? _runtimeHost;
// //
// //   /// Default to your ALB; allow override via --dart-define=API_HOST=...
// //   String get _defaultHost {
// //     const fromEnv = String.fromEnvironment('API_HOST');
// //     if (fromEnv.isNotEmpty) return fromEnv.trim();
// //     return 'http://wfm-backend-alb-60464600.ap-south-1.elb.amazonaws.com';
// //   }
// //
// //   String get _host => (_runtimeHost ?? _defaultHost).replaceAll(RegExp(r'/$'), '');
// //   void setBaseHost(String host) => _runtimeHost = host;
// //
// //   Uri _buildUri(String path, {Map<String, dynamic>? query}) {
// //     final tenant = TenantService.instance.tenantIdOrNull;
// //     if (tenant == null || tenant.isEmpty) {
// //       throw StateError('Tenant not set. Ensure TenantService.setTenantId(...) is called before API usage.');
// //     }
// //     final p = path.startsWith('/') ? path : '/$path';
// //     final u = Uri.parse('$_host/$tenant$p');
// //     if (query == null || query.isEmpty) return u;
// //     return u.replace(queryParameters: {
// //       ...u.queryParameters,
// //       ...query.map((k, v) => MapEntry(k, '$v')),
// //     });
// //   }
// //
// //   Future<Map<String, String>> _headers({bool includeAuth = true, Map<String, String>? extra}) async {
// //     final h = <String, String>{
// //       'Content-Type': 'application/json',
// //       'Accept': 'application/json',
// //     };
// //     if (includeAuth) {
// //       final token = await AuthService.instance.getAccessToken();
// //       if (token != null && token.isNotEmpty) {
// //         h['Authorization'] = 'Bearer $token';
// //       }
// //     }
// //     if (extra != null && extra.isNotEmpty) h.addAll(extra);
// //     return h;
// //   }
// //
// //   // ---- Public helpers -------------------------------------------------------
// //
// //   Future<Map<String, dynamic>> getJson(
// //       String path, {
// //         Map<String, dynamic>? query,
// //         Map<String, String>? headers,
// //         Duration timeout = const Duration(seconds: 25),
// //         bool includeAuth = true,
// //       }) async {
// //     final r = await _sendWithRefresh(
// //       method: 'GET', path: path, query: query, headers: headers,
// //       timeout: timeout, includeAuth: includeAuth,
// //     );
// //     return _decodeMap(r.body);
// //   }
// //
// //   Future<List<dynamic>> getList(
// //       String path, {
// //         Map<String, dynamic>? query,
// //         Map<String, String>? headers,
// //         Duration timeout = const Duration(seconds: 25),
// //         bool includeAuth = true,
// //       }) async {
// //     final r = await _sendWithRefresh(
// //       method: 'GET', path: path, query: query, headers: headers,
// //       timeout: timeout, includeAuth: includeAuth,
// //     );
// //     return _decodeList(r.body);
// //   }
// //
// //   Future<Map<String, dynamic>> postJson(
// //       String path,
// //       Map<String, dynamic> jsonBody, {
// //         Map<String, dynamic>? query,
// //         Map<String, String>? headers,
// //         Duration timeout = const Duration(seconds: 25),
// //         bool includeAuth = true,
// //       }) async {
// //     final r = await _sendWithRefresh(
// //       method: 'POST', path: path, query: query, headers: headers,
// //       body: jsonEncode(jsonBody), timeout: timeout, includeAuth: includeAuth,
// //     );
// //     return _decodeMap(r.body);
// //   }
// //
// //   Future<Map<String, dynamic>> putJson(
// //       String path,
// //       Map<String, dynamic> jsonBody, {
// //         Map<String, dynamic>? query,
// //         Map<String, String>? headers,
// //         Duration timeout = const Duration(seconds: 25),
// //         bool includeAuth = true,
// //       }) async {
// //     final r = await _sendWithRefresh(
// //       method: 'PUT', path: path, query: query, headers: headers,
// //       body: jsonEncode(jsonBody), timeout: timeout, includeAuth: includeAuth,
// //     );
// //     return _decodeMap(r.body);
// //   }
// //
// //   Future<void> deleteJson(
// //       String path, {
// //         Map<String, dynamic>? query,
// //         Map<String, dynamic>? jsonBody,
// //         Map<String, String>? headers,
// //         Duration timeout = const Duration(seconds: 25),
// //         bool includeAuth = true,
// //       }) async {
// //     final r = await _sendWithRefresh(
// //       method: 'DELETE', path: path, query: query, headers: headers,
// //       body: jsonBody == null ? null : jsonEncode(jsonBody),
// //       timeout: timeout, includeAuth: includeAuth,
// //     );
// //     _ensure2xx(r);
// //   }
// //
// //   /// Public ping for ALB health (no auth, no tenant).
// //   Future<void> ping() async {
// //     final uri = Uri.parse('$_host/actuator/health');
// //     final r = await http.get(uri).timeout(const Duration(seconds: 6));
// //     if (r.statusCode < 200 || r.statusCode >= 300) {
// //       throw Exception('Ping failed (status ${r.statusCode})');
// //     }
// //   }
// //
// //   // ---- Core request & refresh ----------------------------------------------
// //
// //   Future<http.Response> _sendWithRefresh({
// //     required String method,
// //     required String path,
// //     Map<String, dynamic>? query,
// //     String? body,
// //     Map<String, String>? headers,
// //     Duration timeout = const Duration(seconds: 25),
// //     bool includeAuth = true,
// //   }) async {
// //     final r1 = await _sendOnce(
// //       method: method, path: path, query: query, body: body,
// //       headers: headers, timeout: timeout, includeAuth: includeAuth,
// //     );
// //     if (r1.statusCode != 401 || !includeAuth) return r1;
// //
// //     // try refresh once
// //     final ok = await _refreshTokens();
// //     if (!ok) return r1;
// //
// //     // retry original call
// //     return _sendOnce(
// //       method: method, path: path, query: query, body: body,
// //       headers: headers, timeout: timeout, includeAuth: includeAuth,
// //     );
// //   }
// //
// //   Future<http.Response> _sendOnce({
// //     required String method,
// //     required String path,
// //     Map<String, dynamic>? query,
// //     String? body,
// //     Map<String, String>? headers,
// //     Duration timeout = const Duration(seconds: 25),
// //     bool includeAuth = true,
// //   }) async {
// //     final uri = _buildUri(path, query: query);
// //     final allHeaders = await _headers(includeAuth: includeAuth, extra: headers);
// //
// //     final client = http.Client();
// //     try {
// //       late http.Response r;
// //       switch (method) {
// //         case 'GET':
// //           r = await client.get(uri, headers: allHeaders).timeout(timeout);
// //           break;
// //         case 'POST':
// //           r = await client.post(uri, headers: allHeaders, body: body).timeout(timeout);
// //           break;
// //         case 'PUT':
// //           r = await client.put(uri, headers: allHeaders, body: body).timeout(timeout);
// //           break;
// //         case 'DELETE':
// //           r = await client.delete(uri, headers: allHeaders, body: body).timeout(timeout);
// //           break;
// //         default:
// //           throw UnsupportedError('HTTP method $method not supported');
// //       }
// //       return r;
// //     } on SocketException catch (e) {
// //       throw Exception('Network error: ${e.message}');
// //     } on HttpException catch (e) {
// //       throw Exception('HTTP error: ${e.message}');
// //     } on FormatException catch (e) {
// //       throw Exception('Invalid response format: ${e.message}');
// //     } on TimeoutException {
// //       throw Exception('Request timed out');
// //     } finally {
// //       client.close();
// //     }
// //   }
// //
// //   Future<bool> _refreshTokens() async {
// //     final tenant = TenantService.instance.tenantIdOrNull;
// //     if (tenant == null || tenant.isEmpty) return false;
// //
// //     final refresh = await AuthService.instance.getRefreshToken();
// //     if (refresh == null || refresh.isEmpty) return false;
// //
// //     final uri = Uri.parse('$_host/$tenant/api/auth/refresh');
// //     final client = http.Client();
// //     try {
// //       final r = await client.post(
// //         uri,
// //         headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
// //         body: jsonEncode({'refreshToken': refresh}),
// //       ).timeout(const Duration(seconds: 15));
// //       if (r.statusCode == 200) {
// //         final map = jsonDecode(r.body) as Map<String, dynamic>;
// //         await AuthService.instance.updateTokensFromRefresh(map);
// //         return true;
// //       }
// //       return false;
// //     } catch (_) {
// //       return false;
// //     } finally {
// //       client.close();
// //     }
// //   }
// //
// //   // ---- JSON helpers ---------------------------------------------------------
// //
// //   Map<String, dynamic> _decodeMap(String body) {
// //     _ensureNotEmpty(body);
// //     final obj = jsonDecode(body);
// //     if (obj is Map<String, dynamic>) return obj;
// //     throw Exception('Expected JSON object, got: $obj');
// //   }
// //
// //   List<dynamic> _decodeList(String body) {
// //     _ensureNotEmpty(body);
// //     final obj = jsonDecode(body);
// //     if (obj is List<dynamic>) return obj;
// //     throw Exception('Expected JSON array, got: $obj');
// //   }
// //
// //   void _ensureNotEmpty(String body) {
// //     if (body.isEmpty) throw Exception('Empty response body');
// //   }
// //
// //   void _ensure2xx(http.Response r) {
// //     if (r.statusCode >= 200 && r.statusCode < 300) return;
// //
// //     String msg = 'HTTP ${r.statusCode}';
// //     try {
// //       final decoded = jsonDecode(r.body);
// //       if (decoded is Map) {
// //         if (decoded['message'] is String) msg = decoded['message'];
// //         else if (decoded['error'] is String) msg = decoded['error'];
// //         else if (decoded['detail'] is String) msg = decoded['detail'];
// //       }
// //     } catch (_) {}
// //     throw Exception(msg);
// //   }
// // }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // lib/data/services/http_client.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// import 'auth_service.dart';
// import 'tenant_service.dart';
//
// class ApiClient {
//   ApiClient._();
//   static final ApiClient instance = ApiClient._();
//
//   // ====== CONFIG ======
//   // Your backend expects: http://HOST/<tenantId>/api/...
//   static const bool _tenantInPath = true;
//
//   // Header name if your server also reads tenant from header (harmless to send both).
//   static const String _tenantHeader = 'X-Tenant-Id';
//   // ====================
//
//   String get _baseHost {
//     const fromEnv = String.fromEnvironment('API_HOST');
//     if (fromEnv.isNotEmpty) return fromEnv; // e.g. http://wfm-backend-alb-...
//     return 'http://wfm-backend-alb-60464600.ap-south-1.elb.amazonaws.com//';
//   }
//
//   Uri _uri(String path) {
//     // absolute URL passthrough
//     if (path.startsWith('http://') || path.startsWith('https://')) {
//       return Uri.parse(path);
//     }
//
//     final tenant = TenantService.instance.tenantIdOrNull;
//
//     // Normalize incoming path (ensure single leading slash)
//     String p = path.startsWith('/') ? path : '/$path';
//
//     // Inject /<tenantId> between host and path if enabled
//     if (_tenantInPath && tenant != null && tenant.isNotEmpty) {
//       // Ensure we don't end up with //tenant or tenant//api
//       p = '/$tenant${p}';
//     }
//
//     // Result: http://HOST/<tenantId>/api/...
//     return Uri.parse('$_baseHost$p');
//   }
//
//   Map<String, String> _headers({Map<String, String>? extra}) {
//     final h = <String, String>{'Content-Type': 'application/json'};
//
//     // Attach Bearer token if present
//     final bearer = SessionController.instance.bearerToken ??
//         (AuthService.instance.accessToken == null
//             ? null
//             : 'Bearer ${AuthService.instance.accessToken}');
//     if (bearer != null) h['Authorization'] = bearer;
//
//     // Also attach tenant header (safe even if server ignores it)
//     final tenant = TenantService.instance.tenantIdOrNull;
//     if (tenant != null && tenant.isNotEmpty) {
//       h[_tenantHeader] = tenant;
//     }
//
//     if (extra != null) h.addAll(extra);
//     return h;
//   }
//
//   Future<Map<String, dynamic>> getJson(String path) async {
//     final res = await http.get(_uri(path), headers: _headers());
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw _httpError('GET', path, res);
//     }
//     final body = res.body.isEmpty ? '{}' : res.body;
//     return jsonDecode(body) as Map<String, dynamic>;
//   }
//
//   Future<List<dynamic>> getList(String path) async {
//     final res = await http.get(_uri(path), headers: _headers());
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw _httpError('GET', path, res);
//     }
//     final body = res.body.isEmpty ? '[]' : res.body;
//     return jsonDecode(body) as List<dynamic>;
//   }
//
//   Future<Map<String, dynamic>> postJson(
//       String path, {
//         Map<String, dynamic>? body,
//         Map<String, String>? headers,
//       }) async {
//     final res = await http.post(
//       _uri(path),
//       headers: _headers(extra: headers),
//       body: body == null ? null : jsonEncode(body),
//     );
//     if (res.statusCode < 200 || res.statusCode >= 300) {
//       throw _httpError('POST', path, res);
//     }
//     final text = res.body;
//     if (text.isEmpty) return <String, dynamic>{};
//     return jsonDecode(text) as Map<String, dynamic>;
//   }
//
//   Exception _httpError(String method, String path, http.Response res) {
//     final msg = '$method $path failed: ${res.statusCode} ${res.body}';
//     return Exception(msg);
//   }
// }
//
//
















// lib/data/services/http_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../app/config/environment.dart';
import 'auth_service.dart';
import 'tenant_service.dart';
import 'routes.dart'; // Import routes to check for /login path

/// A custom exception class for API errors, providing structured data.
class ApiException implements Exception {
  final String method;
  final String path;
  final int statusCode;
  final String body;

  ApiException(this.method, this.path, this.statusCode, this.body);

  @override
  String toString() {
    // Format the message clearly for consumption by other services/UI
    return 'API Error $statusCode on $method $path. Body: $body';
  }
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ====== CONFIG ======
  // Your backend expects: http://HOST/<tenantId>/api/...
  static const bool _tenantInPath = true;

  // Header name if your server also reads tenant from header (harmless to send both).
  static const String _tenantHeader = 'X-Tenant-Id';
  // ====================

  /// Retrieves the base URL from the initialized Environment configuration.
  String get _baseHost {
    return Environment().config.baseUrl;
  }

  Uri _uri(String path) {
    // absolute URL passthrough
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }

    final tenant = TenantService.instance.tenantId; // String? (nullable)

    // CRITICAL CHECK: If the request is not the initial /login call,
    // we MUST have the Tenant ID for protected paths.
    if (path != Routes.login && (tenant == null || tenant.isEmpty)) {
      throw StateError('Cannot build URI for protected path ($path): Tenant ID is missing.');
    }

    // Normalize incoming path (ensure single leading slash)
    String p = path.startsWith('/') ? path : '/$path';

    // Inject /<tenantId> between host and path if enabled
    if (_tenantInPath && tenant != null && tenant.isNotEmpty) {
      // Ensure we don't end up with //tenant or tenant//api
      p = '/$tenant${p}';
    }

    // Result: http://HOST/<tenantId>/api/...
    return Uri.parse('$_baseHost$p');
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Tenant header (if your backend expects it)
    final tenant = TenantService.instance.tenantId;
    if (tenant != null && tenant.isNotEmpty) {
      h['X-Tenant-Id'] = tenant; // or whatever header your server expects
    }

    // Bearer token (skip only for the login call)
    final bearer = AuthService.instance.bearerToken ?? SessionController.instance.bearerToken;
    if (bearer != null && bearer.isNotEmpty /* && path != Routes.login */) {
      h['Authorization'] = bearer;
    }

    if (extra != null) h.addAll(extra);
    return h;
  }


  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await http.get(_uri(path), headers: _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _httpError('GET', path, res);
    }
    final body = res.body.isEmpty ? '{}' : res.body;
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(String path) async {
    final res = await http.get(_uri(path), headers: _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _httpError('GET', path, res);
    }
    final body = res.body.isEmpty ? '[]' : res.body;
    return jsonDecode(body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    final res = await http.post(
      _uri(path),
      headers: _headers(extra: headers),
      body: body == null ? null : jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _httpError('POST', path, res);
    }
    final text = res.body;
    if (text.isEmpty) return <String, dynamic>{};
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Exception _httpError(String method, String path, http.Response res) {
    // Throw the custom exception that includes status and body
    return ApiException(method, path, res.statusCode, res.body);
  }
}