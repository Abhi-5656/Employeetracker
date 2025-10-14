// // // lib/data/services/auth_service.dart
// // import 'package:flutter/foundation.dart';
// //
// // /// Legacy-compatible session facade expected by older code or codegen.
// // /// NOTE: These are FIELDS so reflection/@getters finds them.
// // class SessionController {
// //   SessionController._();
// //   static final SessionController instance = SessionController._();
// //
// //   String? token;         // legacy field name (access token)
// //   String? refreshToken;  // legacy field name
// //
// //   /// Old code tends to look for `isSignedIn` (not `isAuthenticated`)
// //   final ValueNotifier<bool> isSignedIn = ValueNotifier<bool>(false);
// //
// //   String? get bearerToken =>
// //       (token == null || token!.isEmpty) ? null : 'Bearer $token';
// //
// //   /// Legacy initializer forwards to modern service.
// //   Future<void> init() => AuthService.instance.init();
// //
// //   /// Unified, named-args API. This matches your app.dart call sites.
// //   Future<void> signInPersist({
// //     required String accessToken,
// //     required String refreshToken,
// //     String? displayName,
// //   }) {
// //     final payload = <String, dynamic>{
// //       'accessToken': accessToken,
// //       'refreshToken': refreshToken,
// //       if (displayName != null) 'displayName': displayName,
// //     };
// //     return AuthService.instance.signInPersist(payload);
// //   }
// // }
// //
// // /// Global alias (some files import this symbol directly)
// // final SessionController sessionController = SessionController.instance;
// //
// // /// Modern auth service; keeps the legacy SessionController in sync.
// // class AuthService {
// //   AuthService._();
// //   static final AuthService instance = AuthService._();
// //
// //   String? _accessToken;
// //   String? _refreshToken;
// //
// //   /// New reactive flag
// //   final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
// //
// //   // Preferred sync getters
// //   String? get accessToken => _accessToken;
// //   String? get refreshToken => _refreshToken;
// //
// //   // Async getters (kept for callers already awaiting)
// //   Future<String?> getAccessToken() async => _accessToken;
// //   Future<String?> getRefreshToken() async => _refreshToken;
// //
// //   /// Load persisted tokens if you store them (no-op by default).
// //   Future<void> init() async {
// //     // TODO: SharedPreferences/SecureStorage load into _accessToken/_refreshToken
// //     final authed = _accessToken != null && _accessToken!.isNotEmpty;
// //     isAuthenticated.value = authed;
// //
// //     // Keep legacy facade in sync:
// //     sessionController.token = _accessToken;
// //     sessionController.refreshToken = _refreshToken;
// //     sessionController.isSignedIn.value = authed;
// //   }
// //
// //   /// Called after /api/auth/login with { accessToken, refreshToken } (and maybe displayName).
// //   Future<void> signInPersist(Map<String, dynamic> payload) async {
// //     _accessToken  = payload['accessToken'] as String?;
// //     _refreshToken = payload['refreshToken'] as String?;
// //
// //     // TODO: persist if desired
// //
// //     final authed = _accessToken != null && _accessToken!.isNotEmpty;
// //     isAuthenticated.value = authed;
// //
// //     // Sync legacy facade:
// //     sessionController.token = _accessToken;
// //     sessionController.refreshToken = _refreshToken;
// //     sessionController.isSignedIn.value = authed;
// //   }
// //
// //   /// Called after /api/auth/refresh with at least { accessToken }.
// //   Future<void> updateTokensFromRefresh(Map<String, dynamic> payload) async {
// //     _accessToken  = payload['accessToken'] as String?;
// //     _refreshToken = (payload['refreshToken'] as String?) ?? _refreshToken;
// //
// //     // TODO: persist if desired
// //
// //     final authed = _accessToken != null && _accessToken!.isNotEmpty;
// //     isAuthenticated.value = authed;
// //
// //     // Sync legacy facade:
// //     sessionController.token = _accessToken;
// //     sessionController.refreshToken = _refreshToken;
// //     sessionController.isSignedIn.value = authed;
// //   }
// //
// //   Future<void> signOut() async {
// //     _accessToken = null;
// //     _refreshToken = null;
// //
// //     // TODO: clear persistence if used
// //
// //     isAuthenticated.value = false;
// //
// //     // Sync legacy facade:
// //     sessionController.token = null;
// //     sessionController.refreshToken = null;
// //     sessionController.isSignedIn.value = false;
// //   }
// // }
//
// //
// //
// // // lib/data/services/auth_service.dart
// // import 'package:flutter/foundation.dart';
// //
// // /// Legacy-compatible session facade expected by older code.
// // /// (Some of your code may still reference this.)
// // class SessionController {
// //   SessionController._();
// //   static final SessionController instance = SessionController._();
// //
// //   String? token;         // access token
// //   String? refreshToken;  // refresh token (optional)
// //   String? employeeId;    // <-- set at login from backend response
// //   String? employeeName;  // optional, used for greeting, etc.
// //
// //   /// Older code expects this, keep it in sync with AuthService.isAuthenticated.
// //   final ValueNotifier<bool> isSignedIn = ValueNotifier<bool>(false);
// //
// //   String? get bearerToken =>
// //       (token == null || token!.isEmpty) ? null : 'Bearer $token';
// //
// //   void clear() {
// //     token = null;
// //     refreshToken = null;
// //     employeeId = null;
// //     employeeName = null;
// //     isSignedIn.value = false;
// //   }
// // }
// //
// // /// Modern service used by the app. Keep SessionController in sync for back-compat.
// // class AuthService {
// //   AuthService._();
// //   static final AuthService instance = AuthService._();
// //
// //   final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
// //
// //   // In-memory copies (mirror of SessionController)
// //   String? _accessToken;
// //   String? _refreshToken;
// //   String? _employeeId;
// //   String? _employeeName;
// //
// //   Future<void> init() async {
// //     // If you add persistence later (SharedPreferences/SecureStorage),
// //     // restore here and set isAuthenticated accordingly.
// //     isAuthenticated.value = _accessToken != null && _accessToken!.isNotEmpty;
// //   }
// //
// //   /// Preferred entry-point from a successful login.
// //   void applyLogin({
// //     required String accessToken,
// //     // required String employeeId,
// //     String? refreshToken,
// //     String? employeeName,
// //   }) {
// //     // Update modern fields
// //     _accessToken = accessToken;
// //     _refreshToken = refreshToken;
// //     _employeeId = employeeId;
// //     _employeeName = employeeName;
// //     isAuthenticated.value = true;
// //
// //     // Sync legacy facade for older code
// //     final s = SessionController.instance;
// //     s.token = _accessToken;
// //     s.refreshToken = _refreshToken;
// //     s.employeeId = _employeeId;
// //     s.employeeName = _employeeName;
// //     s.isSignedIn.value = true;
// //   }
// //
// //   // Call this after /api/auth/me
// //   void updateProfile({String? employeeId, String? employeeName}) {
// //     if (employeeId != null && employeeId.isNotEmpty) _employeeId = employeeId;
// //     if (employeeName != null && employeeName.isNotEmpty) _employeeName = employeeName;
// //
// //     final s = SessionController.instance;
// //     if (employeeId != null && employeeId.isNotEmpty) s.employeeId = employeeId;
// //     if (employeeName != null && employeeName.isNotEmpty) s.employeeName = employeeName;
// //   }
// //
// //   /// LEGACY bridge for any call sites still passing a Map.
// //   /// Accepts both { accessToken, employeeId } or nested responses.
// //   Future<void> signInPersist(Map<String, dynamic> map) async {
// //     // Try common shapes
// //     final accessToken = (map['accessToken'] ??
// //         map['token'] ??
// //         map['access_token']) as String?;
// //     final refreshToken = (map['refreshToken'] ??
// //         map['refresh_token']) as String?;
// //     final employeeId = (map['employeeId'] ??
// //         map['empId'] ??
// //         map['empID'] ??
// //         (map['user'] is Map ? (map['user']['employeeId'] ?? map['user']['empId']) : null)) as String?;
// //     final employeeName = (map['employeeName'] ??
// //         map['name'] ??
// //         (map['user'] is Map ? map['user']['name'] : null)) as String?;
// //
// //     if (accessToken == null || accessToken.isEmpty) {
// //       throw StateError('Login result missing access token.');
// //     }
// //     // if (employeeId == null || employeeId.isEmpty) {
// //     //   throw StateError('Login result missing employeeId.');
// //     // }
// //
// //     applyLogin(
// //       accessToken: accessToken,
// //       // employeeId: employeeId,
// //       refreshToken: refreshToken,
// //       employeeName: employeeName,
// //     );
// //   }
// //
// //   String? get accessToken => _accessToken;
// //   String? get refreshToken => _refreshToken;
// //   String? get employeeId => _employeeId;
// //   String? get employeeName => _employeeName;
// //
// //   Future<void> signOut() async {
// //     _accessToken = null;
// //     _refreshToken = null;
// //     _employeeId = null;
// //     _employeeName = null;
// //
// //     isAuthenticated.value = false;
// //
// //     // Sync legacy facade:
// //     SessionController.instance.clear();
// //   }
// // }










// lib/data/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/tenant_service.dart';
import 'auth_api.dart'; // your existing API wrapper for /login and /refresh
/// Legacy-compatible session facade expected by older code.
/// (Some of your code may still reference this.)
class SessionController {
  SessionController._();
  static final SessionController instance = SessionController._();

  String? token;         // access token
  String? refreshToken;  // refresh token (optional)
  String? employeeId;    // <-- set at login from backend response
  String? employeeName;  // optional, used for greeting, etc.
  String? email; // For legacy sync

  /// Older code expects this, keep it in sync with AuthService.isAuthenticated.
  final ValueNotifier<bool> isSignedIn = ValueNotifier<bool>(false);

  String? get bearerToken =>
      (token == null || token!.isEmpty) ? null : 'Bearer $token';

  void clear() {
    token = null;
    refreshToken = null;
    employeeId = null;
    employeeName = null;
    email = null;
    isSignedIn.value = false;
  }
}

/// Modern service used by the app. Keep SessionController in sync for back-compat.
class AuthService {

  Future<void> updateExpiryEpoch(int epochSeconds) async {
    _accessExpiryEpoch = epochSeconds;
    await _storage.write(key: _kKeyExpiryEpoch, value: epochSeconds.toString());
  }

  /// Best-effort display name without hitting the network.
  /// Prefers employeeName; falls back to email's local part.
  String get displayName {
    final n = _employeeName?.trim();
    if (n != null && n.isNotEmpty) return n;

    final e = _email;
    if (e == null || e.isEmpty) return 'Employee';
    final local = e.split('@').first;

    // Title-case the local part, replacing separators
    final cleaned = local.replaceAll('.', ' ').replaceAll('_', ' ').replaceAll('-', ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
  }

  AuthService._();
  static final AuthService instance = AuthService._();

  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
  // Use encrypted shared prefs on Android by default
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kKeyAccessToken   = 'access_token';
  static const _kKeyRefreshToken  = 'refresh_token';
  static const _kKeyExpiryEpoch   = 'access_expiry_epoch'; // seconds since epoch
  static const _kKeyEmployeeId    = 'employee_id';
  static const _kKeyEmployeeName  = 'employee_name';
  static const _kKeyEmail         = 'email';

  // In-memory copies (mirror of SessionController)
  String? _accessToken;
  String? _refreshToken;
  int? _accessExpiryEpoch; // seconds
  String? _employeeId;
  String? _employeeName;
  String? _email;

// READERS if some screens need these:
  String? get accessToken   => _accessToken;
  String? get refreshToken  => _refreshToken;
  String? get employeeId    => _employeeId;
  String? get employeeName  => _employeeName;
  String? get email         => _email;

  String? get bearerToken =>
      (_accessToken == null || _accessToken!.isEmpty) ? null : 'Bearer $_accessToken';

  Future<void> init() async {
    // 1) Restore from secure storage
    _accessToken      = await _storage.read(key: _kKeyAccessToken);
    _refreshToken     = await _storage.read(key: _kKeyRefreshToken);
    _employeeId       = await _storage.read(key: _kKeyEmployeeId);
    _employeeName     = await _storage.read(key: _kKeyEmployeeName);
    _email            = await _storage.read(key: _kKeyEmail);
    final expiryStr   = await _storage.read(key: _kKeyExpiryEpoch);
    _accessExpiryEpoch = expiryStr != null ? int.tryParse(expiryStr) : null;

// 2) If we have a refresh token, silently refresh access if needed
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      final ok = await _ensureValidAccessToken();
      if (!ok) await signOut(); // wipe corrupted/expired sessions
    }
    // If you add persistence later (SharedPreferences/SecureStorage),
    // restore here and set isAuthenticated accordingly.
    // 3) Compute current auth state
    isAuthenticated.value = _accessToken != null && _accessToken!.isNotEmpty;

    // 4) ✅ Sync legacy SessionController so old call-sites keep working
    final s = SessionController.instance;
    s.token        = _accessToken;
    s.refreshToken = _refreshToken;
    s.employeeId   = _employeeId;
    s.employeeName = _employeeName;
    s.email        = _email;
    s.isSignedIn.value = isAuthenticated.value;
  }

  /// Preferred entry-point from a successful login.
  void applyLogin({
    required String accessToken,
    String? email,
    required String employeeId, // <<< FIX: Re-enabled required employeeId
    String? refreshToken,
    String? employeeName,
  }) {
    // Update in-memory state
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _email = email;                 // ✅ FIX: no local var; assign the field
    _employeeId = employeeId;
    _employeeName = employeeName;
    // _accessExpiryEpoch stays null unless server gives it elsewhere
    isAuthenticated.value = true;

    // Sync legacy facade for older code
    final s = SessionController.instance;
    s.token = _accessToken;
    s.refreshToken = _refreshToken;
    s.employeeId = _employeeId; // <<< FIX: Set employeeId for legacy controller
    s.employeeName = _employeeName;
    s.email = _email;
    s.isSignedIn.value = true;

// ✅ Persist immediately so the next app launch restores the session
    // (no await needed; safe to fire-and-forget here)

    _persist();

  }

  // Call this after /api/auth/me
  void updateProfile({String? employeeId, String? employeeName}) {
    if (employeeId != null && employeeId.isNotEmpty) _employeeId = employeeId;
    if (employeeName != null && employeeName.isNotEmpty) _employeeName = employeeName;

    final s = SessionController.instance;
    if (employeeId != null && employeeId.isNotEmpty) s.employeeId = employeeId;
    if (employeeName != null && employeeName.isNotEmpty) s.employeeName = employeeName;

    // ✅ Persist updated profile fields too
    _persist();
  }

  /// LEGACY bridge for any call sites still passing a Map.
  /// Accepts both { accessToken, employeeId } or nested responses.
  Future<void> signInPersist(Map<String, dynamic> map) async {
    // Try common shapes
    final accessToken = (map['accessToken'] ??
        map['token'] ??
        map['access_token']) as String?;
    final refreshToken = (map['refreshToken'] ??
        map['refresh_token']) as String?;
    final employeeId = (map['employeeId'] ??
        map['empId'] ??
        map['empID'] ??
        (map['user'] is Map ? (map['user']['employeeId'] ?? map['user']['empId']) : null)) as String?;
    final employeeName = (map['employeeName'] ??
        map['name'] ??
        (map['user'] is Map ? map['user']['name'] : null)) as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Login result missing access token.');
    }

    // The check below is implicitly done in applyLogin, but let's keep it explicit for clarity
    if (employeeId == null || employeeId.isEmpty) {
      throw StateError('Login result missing employeeId.');
    }

    applyLogin(
      accessToken: accessToken,
      employeeId: employeeId, // <<< FIX: Passed the mandatory employeeId
      refreshToken: refreshToken,
      employeeName: employeeName,
    );
  }



  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _accessExpiryEpoch = null;
    _employeeId = null;
    _employeeName = null;
    _email = null;
    isAuthenticated.value = false;

    await _storage.delete(key: _kKeyAccessToken);
    await _storage.delete(key: _kKeyRefreshToken);
    await _storage.delete(key: _kKeyExpiryEpoch);
    await _storage.delete(key: _kKeyEmployeeId);
    await _storage.delete(key: _kKeyEmployeeName);
    await _storage.delete(key: _kKeyEmail);

    // ✅ keep old callers consistent
    SessionController.instance.clear();
  }
  bool get _isAccessTokenValid {
    if (_accessToken == null || _accessToken!.isEmpty) return false;
    if (_accessExpiryEpoch == null) return true; // backend didn't give expiry
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSec + 60 < _accessExpiryEpoch!; // renew 60s early
  }

  Future<bool> _ensureValidAccessToken() async {
    if (_isAccessTokenValid) return true;
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;

    try {
      // final tenant = TenantService.instance.tenantId ?? '';
      final r = await AuthApi.instance.refresh(
        refreshToken: _refreshToken!,
      );

      if (r == null || r.accessToken.isEmpty) return false;

      _accessToken = r.accessToken;
      if (r.refreshToken != null && r.refreshToken!.isNotEmpty) {
        _refreshToken = r.refreshToken; // ✅ keep it current if backend rotates
      }
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _accessExpiryEpoch = (nowSec + (r.expiresIn ?? 3600)) as int?;

      // ✅ Persist updated tokens/expiry
      await _storage.write(key: _kKeyAccessToken, value: _accessToken);
      await _storage.write(key: _kKeyRefreshToken, value: _refreshToken);
      await _storage.write(key: _kKeyExpiryEpoch, value: _accessExpiryEpoch!.toString());
      return true;
    } catch (e) {
      debugPrint('Refresh failed: $e');
      return false;
    }
  }

  Future<void> _persist() async {
    await _storage.write(key: _kKeyAccessToken, value: _accessToken);
    await _storage.write(key: _kKeyRefreshToken, value: _refreshToken);
    await _storage.write(key: _kKeyEmployeeId, value: _employeeId);
    await _storage.write(key: _kKeyEmployeeName, value: _employeeName);
    await _storage.write(key: _kKeyEmail, value: _email);
    if (_accessExpiryEpoch != null) {
      await _storage.write(key: _kKeyExpiryEpoch, value: _accessExpiryEpoch!.toString());
    }
  }

}


// // lib/data/services/auth_service.dart
// import 'package:flutter/foundation.dart';
//
// /// Legacy-compatible session facade expected by older code.
// class SessionController {
//   SessionController._();
//   static final SessionController instance = SessionController._();
//
//   String? token;
//   String? refreshToken;
//   String? employeeId;
//   String? employeeName;
//   String? email; // <<< ADDED: To store the user's email
//
//   final ValueNotifier<bool> isSignedIn = ValueNotifier<bool>(false);
//
//   String? get bearerToken =>
//       (token == null || token!.isEmpty) ? null : 'Bearer $token';
//
//   void clear() {
//     token = null;
//     refreshToken = null;
//     employeeId = null;
//     employeeName = null;
//     email = null; // <<< ADDED: Clear email
//     isSignedIn.value = false;
//   }
// }
//
// /// Modern service used by the app.
// class AuthService {
//   AuthService._();
//   static final AuthService instance = AuthService._();
//
//   final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
//
//   // In-memory session data
//   String? _accessToken;
//   String? _refreshToken;
//   String? _employeeId;
//   String? _employeeName;
//   String? _email; // <<< ADDED: To store the user's email
//
//   Future<void> init() async {
//     isAuthenticated.value = _accessToken != null && _accessToken!.isNotEmpty;
//   }
//
//   /// Preferred entry-point from a successful login.
//   void applyLogin({
//     required String accessToken,
//     required String email, // <<< CHANGED: Email is now required
//     String? employeeId,   // <<< CHANGED: EmployeeId is now optional
//     String? refreshToken,
//     String? employeeName,
//   }) {
//     // Update modern fields
//     _accessToken = accessToken;
//     _refreshToken = refreshToken;
//     _employeeId = employeeId;
//     _employeeName = employeeName;
//     _email = email; // <<< ADDED: Set the email
//     isAuthenticated.value = true;
//
//     // Sync legacy facade for older code
//     final s = SessionController.instance;
//     s.token = _accessToken;
//     s.refreshToken = _refreshToken;
//     s.employeeId = _employeeId;
//     s.employeeName = _employeeName;
//     s.email = _email; // <<< ADDED: Sync email to legacy controller
//     s.isSignedIn.value = true;
//   }
//
//   // This can still be used to update secondary info if the /me endpoint works
//   void updateProfile({String? employeeId, String? employeeName}) {
//     if (employeeId != null && employeeId.isNotEmpty) _employeeId = employeeId;
//     if (employeeName != null && employeeName.isNotEmpty) _employeeName = employeeName;
//
//     final s = SessionController.instance;
//     if (employeeId != null && employeeId.isNotEmpty) s.employeeId = employeeId;
//     if (employeeName != null && employeeName.isNotEmpty) s.employeeName = employeeName;
//   }
//
//   String? get accessToken => _accessToken;
//   String? get refreshToken => _refreshToken;
//   String? get employeeId => _employeeId;
//   String? get employeeName => _employeeName;
//   String? get email => _email; // <<< ADDED: Public getter for email
//
//   Future<void> signOut() async {
//     _accessToken = null;
//     _refreshToken = null;
//     _employeeId = null;
//     _employeeName = null;
//     _email = null; // <<< ADDED: Clear email on sign out
//     isAuthenticated.value = false;
//
//     // Sync legacy facade:
//     SessionController.instance.clear();
//   }
// }