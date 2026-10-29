/// Central API configuration for NabhKrishi local backend (FastAPI).
library;
///
/// =========================================================================
/// HOW TO CONFIGURE YOUR LAPTOP LAN IPV4 ADDRESS:
/// =========================================================================
/// 1. Open PowerShell / Command Prompt on your laptop.
/// 2. Run: ipconfig
/// 3. Look for your active Wi-Fi adapter's "IPv4 Address".
/// 4. Replace `<LAPTOP_IPV4>` in [apiBaseUrl] below with your laptop's IP.
///
/// Example:
///   const String apiBaseUrl = 'http://192.168.1.100:8000';
///
/// Alternatively, you can run the app without changing code by passing:
///   flutter run --dart-define=BACKEND_URL=http://your_laptop_ip:8000
/// =========================================================================

const String apiBaseUrl = 'http://10.12.127.140:8000';

class ApiConstants {
  ApiConstants._();

  /// Resolves the active base URL:
  /// 1. Uses `--dart-define=BACKEND_URL=...` if provided via CLI.
  /// 2. Otherwise falls back to [apiBaseUrl].
  static String get resolvedBaseUrl {
    const envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl.endsWith('/')
          ? envUrl.substring(0, envUrl.length - 1)
          : envUrl;
    }
    return apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
  }

  /// Whether the user has replaced `<LAPTOP_IPV4>` with a real IP or URL.
  static bool get isConfigured {
    final url = resolvedBaseUrl;
    return !url.contains('<LAPTOP_IPV4>');
  }

  /// Health status endpoint (GET)
  static String get healthEndpoint => '$resolvedBaseUrl/health';

  /// Chatbot endpoint (POST)
  static String get chatEndpoint => '$resolvedBaseUrl/chat';

  /// Swin-T Crop Disease Prediction endpoint (POST multipart)
  static String get predictEndpoint => '$resolvedBaseUrl/predict';
}
