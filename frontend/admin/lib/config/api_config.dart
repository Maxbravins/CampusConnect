class ApiConfig {
  // Admin panel runs in a browser (Flutter Web), so "localhost" is correct here
  // — unlike the mobile app, there's no emulator networking quirk to worry about.
  static const String baseUrl = "http://localhost:5000/api";
}
