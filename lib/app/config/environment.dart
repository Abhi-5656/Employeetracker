// lib/app/config/environment.dart
import '././prod_config.dart';
import '././staging_config.dart';

import 'dev_config.dart';
import 'env_config.dart';

class Environment {
  factory Environment() {
    return _singleton;
  }

  Environment._internal();

  static final Environment _singleton = Environment._internal();

  static const String dev = 'dev';
  static const String staging = 'staging';
  static const String prod = 'prod';

  /// Holds the configuration object (Dev, Staging, or Prod).
  late EnvConfig config;

  /// Initializes the environment configuration based on the provided string.
  void init(String environment) {
    config = _getConfig(environment);
  }

  EnvConfig _getConfig(String environment) {
    switch (environment) {
      case dev:
        return DevConfig();
      case staging:
        return StagingConfig();
      case prod:
        return ProdConfig();
      default:
      // Default to Production if an unknown environment is passed
        return ProdConfig();
    }
  }
}