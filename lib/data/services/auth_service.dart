// lib/data/services/auth_service.dart
import 'dart:convert'; // for base64/json decode
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_api.dart';

/// Legacy-compatible session facade expected by older code.
class SessionController {
  SessionController._();
  static final SessionController instance = SessionController._();

  String? token;         // access token
  String? refreshToken;  // refresh token (optional)
  String? employeeId;    // <-- set at login from backend response
  String? employeeName;  // optional
  String? email;         // For legacy sync

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
  static const _kKeyHasReportees  = 'has_reportees';

  // In-memory copies
  String? _accessToken;
  String? _refreshToken;
  int? _accessExpiryEpoch; // seconds
  String? _employeeId;
  String? _employeeName;
  String? _email;
  bool hasReportees = false;

  // --- GETTERS ---
  String? get accessToken   => _accessToken;

  /// Alias for legacy code or background services expecting 'token'
  String? get token         => _accessToken;

  String? get refreshToken  => _refreshToken;
  String? get employeeId    => _employeeId;
  String? get employeeName  => _employeeName;
  String? get email         => _email;

  String? get bearerToken =>
      (_accessToken == null || _accessToken!.isEmpty) ? null : 'Bearer $_accessToken';

  /// Load persisted tokens.
  Future<void> init() async {
    _accessToken      = await _storage.read(key: _kKeyAccessToken);
    _refreshToken     = await _storage.read(key: _kKeyRefreshToken);
    _employeeId       = await _storage.read(key: _kKeyEmployeeId);
    _employeeName     = await _storage.read(key: _kKeyEmployeeName);
    _email            = await _storage.read(key: _kKeyEmail);
    final expiryStr   = await _storage.read(key: _kKeyExpiryEpoch);
    _accessExpiryEpoch = expiryStr != null ? int.tryParse(expiryStr) : null;
    hasReportees      = (await _storage.read(key: _kKeyHasReportees)) == 'true';

    // Silently refresh access if needed and possible
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      final ok = await _ensureValidAccessToken();
      if (!ok) await signOut(); // wipe corrupted/expired sessions
    }

    isAuthenticated.value = _accessToken != null && _accessToken!.isNotEmpty;

    // Sync legacy SessionController
    _syncLegacyController();
  }

  /// Best-effort display name.
  String get displayName {
    final n = _employeeName?.trim();
    if (n != null && n.isNotEmpty) return n;

    final e = _email;
    if (e == null || e.isEmpty) return 'Employee';
    final local = e.split('@').first;

    final cleaned = local.replaceAll('.', ' ').replaceAll('_', ' ').replaceAll('-', ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
  }

  // --- NEW METHODS REQUIRED BY OTHER FILES ---

  /// Called by AuthApi to update the expiry time from JWT
  Future<void> updateExpiryEpoch(int epochSeconds) async {
    _accessExpiryEpoch = epochSeconds;
    await _storage.write(key: _kKeyExpiryEpoch, value: epochSeconds.toString());
  }

  /// Used by the Background Service to manually set the token
  /// because Isolates do not share memory with the main app.
  void setTokenManual(String token) {
    _accessToken = token;
    isAuthenticated.value = true;
    // Sync to legacy controller just in case background service uses it
    SessionController.instance.token = token;
  }

  Future<void> setHasReportees(bool value) async {
    hasReportees = value;
    await _persist();
  }

  // -------------------------------------------

  /// Entry-point from a successful login.
  void applyLogin({
    required String accessToken,
    required String employeeId,
    String? email,
    String? refreshToken,
    String? employeeName,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _email = email;
    _employeeId = employeeId;
    _employeeName = employeeName;

    final claims = _decodeJwtPayload(accessToken);
    if (claims != null) {
      final exp = claims['exp'];
      if (exp is num) {
        _accessExpiryEpoch = exp.toInt();
      }
      _employeeName ??= claims['fullName'] as String?;
      _email        ??= claims['sub']      as String?;
    }

    isAuthenticated.value = true;
    _syncLegacyController();
    _persist();
  }

  // Call this after /api/auth/me
  void updateProfile({String? employeeId, String? employeeName}) {
    if (employeeId != null && employeeId.isNotEmpty) _employeeId = employeeId;
    if (employeeName != null && employeeName.isNotEmpty) _employeeName = employeeName;
    _syncLegacyController();
    _persist();
  }

  /// Legacy bridge for Map-based logins
  Future<void> signInPersist(Map<String, dynamic> map) async {
    final accessToken = (map['accessToken'] ?? map['token'] ?? map['access_token']) as String?;
    final refreshToken = (map['refreshToken'] ?? map['refresh_token']) as String?;

    // Handle nested 'user' object if present
    final userObj = map['user'] is Map ? map['user'] : {};
    final employeeId = (map['employeeId'] ?? map['empId'] ?? map['empID'] ?? userObj['employeeId'] ?? userObj['empId']) as String?;
    final employeeName = (map['employeeName'] ?? map['name'] ?? userObj['name']) as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Login result missing access token.');
    }
    if (employeeId == null || employeeId.isEmpty) {
      throw StateError('Login result missing employeeId.');
    }

    applyLogin(
      accessToken: accessToken,
      employeeId: employeeId,
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
    hasReportees = false;
    isAuthenticated.value = false;

    await _storage.deleteAll();
    SessionController.instance.clear();
  }

  Future<bool> ensureValidAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _isAccessTokenValid) return true;
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;

    try {
      final r = await AuthApi.instance.refresh(refreshToken: _refreshToken!);

      if (r == null || r.accessToken.isEmpty) {
        await signOut();
        return false;
      }

      _updateSessionFromRefresh(r);
      await _persist();
      return true;
    } catch (e) {
      debugPrint('Refresh failed during ensure check: $e');
      await signOut();
      return false;
    }
  }

  // --- Internal Helpers ---

  void _syncLegacyController() {
    final s = SessionController.instance;
    s.token        = _accessToken;
    s.refreshToken = _refreshToken;
    s.employeeId   = _employeeId;
    s.employeeName = _employeeName;
    s.email        = _email;
    s.isSignedIn.value = isAuthenticated.value;
  }

  bool get _isAccessTokenValid {
    if (_accessToken == null || _accessToken!.isEmpty) return false;
    if (_accessExpiryEpoch == null) return true;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSec + 60 < _accessExpiryEpoch!; // renew 60s early
  }

  Future<bool> _ensureValidAccessToken() async {
    return ensureValidAccessToken();
  }

  void _updateSessionFromRefresh(dynamic r) {
    _accessToken = r.accessToken;
    if (r.refreshToken != null && r.refreshToken!.isNotEmpty) {
      _refreshToken = r.refreshToken;
    }
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _accessExpiryEpoch = (nowSec + (r.expiresIn ?? 3600)) as int?;
  }

  Future<void> _persist() async {
    await _storage.write(key: _kKeyAccessToken, value: _accessToken);
    await _storage.write(key: _kKeyRefreshToken, value: _refreshToken);
    await _storage.write(key: _kKeyEmployeeId, value: _employeeId);
    await _storage.write(key: _kKeyEmployeeName, value: _employeeName);
    await _storage.write(key: _kKeyEmail, value: _email);
    await _storage.write(key: _kKeyHasReportees, value: hasReportees.toString());
    if (_accessExpiryEpoch != null) {
      await _storage.write(key: _kKeyExpiryEpoch, value: _accessExpiryEpoch!.toString());
    }
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String norm(String s) {
        switch (s.length % 4) {
          case 0: return s;
          case 2: return s + '==';
          case 3: return s + '=';
          default: return s;
        }
      }
      final payload = base64Url.decode(norm(parts[1]));
      return jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}