import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Endpoint constants. Fill in per-project.
///
/// Feature modules reference constants here as:
///   `ApiConstants.featureNameEndpoint`
abstract final class ApiConstants {
  /// Base URL for all API requests. Update per environment via .env.
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'https://api.example.com/v1';

  // ── Add feature endpoints below ──────────────────────────────────────
  // static String get userProfileEndpoint => '$baseUrl/user/profile';
  // static String get settingsEndpoint => '$baseUrl/settings';
}
