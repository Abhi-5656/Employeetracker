// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// import 'app/app.dart';
// import 'app/config/environment.dart';
// import 'data/services/tenant_service.dart';
// import 'data/services/auth_service.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // 1. Determine the environment ('dev', 'staging', or 'prod')
//   // Prioritize the compile-time flag 'ENVIRONMENT', otherwise default based on build mode.
//   const String environment = String.fromEnvironment(
//     'ENVIRONMENT',
//     defaultValue: kReleaseMode ? Environment.prod : Environment.dev,
//   );
//
//   // 2. Initialize the environment configuration (sets the Base URL, etc.)
//   Environment().init(environment);
//
//   // 3. Load the corresponding .env file for secrets/other configuration
//   String envFileName;
//   switch (environment) {
//     case Environment.dev:
//       envFileName = '.env.dev';
//       break;
//     case Environment.staging:
//       envFileName = '.env.staging';
//       break;
//     case Environment.prod:
//     default:
//       envFileName = '.env.prod';
//       break;
//   }
//   await dotenv.load(fileName: envFileName);
//
//   // Load persisted tenant + tokens
//   await TenantService.instance.init();
//   await AuthService.instance.init();
//
//   runApp(const WfmApp());
// }

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'app/config/environment.dart';
import 'data/services/tenant_service.dart';
import 'data/services/auth_service.dart';

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

  // 5) Boot the app
  runApp(const WfmApp());
}
