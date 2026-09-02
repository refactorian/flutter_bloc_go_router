/// App environment enum
enum AppEnvironment { dev, staging, prod }

/// Centralized configuration and environment variables.
class AppConfig {
  final AppEnvironment environment;
  final String appTitle;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableNetworkLogging;

  const AppConfig({
    this.environment = AppEnvironment.prod,
    this.appTitle = 'Flutter BLoC & GoRouter',
    this.apiBaseUrl = 'https://jsonplaceholder.typicode.com',
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.enableNetworkLogging = true,
  });

  bool get isDevelopment => environment == AppEnvironment.dev;
}
