// lib/app/config/env_config.dart

/// Defines the contract for all environment-specific configurations.
abstract class EnvConfig {
  /// The base URL for API calls in the current environment.
  String get baseUrl;
}
