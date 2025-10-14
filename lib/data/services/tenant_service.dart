// // lib/data/services/tenant_service.dart
// import 'package:flutter/foundation.dart';
//
// class TenantService {
//   TenantService._();
//   static final TenantService instance = TenantService._();
//
//   /// Reactive tenant id expected by old code: tenantController.tenantId.value
//   final ValueNotifier<String?> tenantId = ValueNotifier<String?>(null);
//
//   /// Load persisted tenant if you store it (no-op here).
//   Future<void> init() async {
//     // TODO: SharedPreferences/SecureStorage load if needed, then:
//     // tenantId.value = loadedTenantId;
//   }
//
//   /// Old code may call this in async style.
//   Future<void> setTenantId(String v) async {
//     tenantId.value = v.trim();
//     // TODO: persist if desired
//   }
//
//   /// Newer, simple getters (keep these too).
//   String? get tenantIdOrNull => tenantId.value;
//   String get tenant {
//     final t = tenantId.value;
//     if (t == null || t.isEmpty) {
//       throw StateError('Tenant not set');
//     }
//     return t;
//   }
// }
//
// /// Back-compat alias so app.dart can keep using `tenantController`
// final TenantService tenantController = TenantService.instance;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TenantService {
  TenantService._();
  static final TenantService instance = TenantService._();

  static const _kKeyTenantId = 'tenant_id';

  /// Reactive tenant id (nullable by design)
  final ValueNotifier<String?> _tenantId = ValueNotifier<String?>(null);

  /// Observe tenant changes if UI wants to react
  ValueListenable<String?> get tenantIdListenable => _tenantId;

  /// Read the current tenant
  String? get tenantId => _tenantId.value;

  /// Null-safe convenience
  bool get hasTenant {
    final t = _tenantId.value;
    return t != null && t.isNotEmpty;
  }

  /// Load persisted tenant id at app startup
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _tenantId.value = prefs.getString(_kKeyTenantId);
  }

  /// Save/overwrite tenant id after Setup screen success
  Future<void> setTenantId(String tenant) async {
    final prefs = await SharedPreferences.getInstance();
    final t = tenant.trim();
    _tenantId.value = t;
    await prefs.setString(_kKeyTenantId, t);
  }

  /// Optional: clear tenant (e.g., full sign-out)
  Future<void> clearTenant() async {
    final prefs = await SharedPreferences.getInstance();
    _tenantId.value = null;
    await prefs.remove(_kKeyTenantId);
  }
}

