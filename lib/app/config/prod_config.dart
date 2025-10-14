// lib/app/config/prod_config.dart

import 'env_config.dart';

class ProdConfig implements EnvConfig {
  @override
  // Placeholder URL for your production environment.
  String get baseUrl => 'https://api.your-api.com';
}