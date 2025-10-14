// lib/app/config/staging_config.dart

import 'env_config.dart';

class StagingConfig implements EnvConfig {
  @override
  // Placeholder URL for your staging environment.
  String get baseUrl => 'https://staging.your-api.com';
}