import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'app/config/environment.dart';
import 'data/services/tenant_service.dart';
import 'data/services/auth_service.dart';
// 👇 ADD THIS IMPORT
import 'data/services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Pick environment from --dart-define=ENVIRONMENT=dev|staging|prod
  //    Defaults to prod in release, dev in debug/profile.
  const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: kReleaseMode ? Environment.prod : Environment.dev,
  );

  // 2) Initialize your typed config (base URLs etc.)
  Environment().init(environment);

  // 3) Load the corresponding .env file shipped as a Flutter asset
  //    (files must exist at assets/env/.env.dev|.env.staging|.env.prod)
  final String envAssetPath = switch (environment) {
    Environment.dev     => 'assets/env/.env.dev',
    Environment.staging => 'assets/env/.env.staging',
    _                   => 'assets/env/.env.prod',
  };

  try {
    await dotenv.load(fileName: envAssetPath);
  } catch (e) {
    // Don’t crash the app—log and continue so your Environment() config still works.
    debugPrint('WARN: Failed to load $envAssetPath -> $e');
  }

  // 4) Load persisted tenant + tokens
  await TenantService.instance.init();
  await AuthService.instance.init();

  // 5) 👇 INITIALIZE BACKGROUND LOCATION SERVICE HERE
  // This ensures the service is ready to handle tracking even if the app is minimized.
  await LocationService.instance.initialize();

  // 6) Boot the app
  runApp(const WfmApp());
}