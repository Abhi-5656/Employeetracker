// lib/app/config/dev_config.dart

import 'env_config.dart';

class DevConfig implements EnvConfig {
  @override
  // Base URL for the development environment.
  // Note: Using http for local/internal network connections.
  // String get baseUrl => 'http://192.168.1.5:8080';
  String get baseUrl => 'http://wfm-backend-alb-60464600.ap-south-1.elb.amazonaws.com';
}
