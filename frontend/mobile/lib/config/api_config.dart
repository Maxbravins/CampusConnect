class ApiConfig {
  // Android emulator -> host machine's localhost is 10.0.2.2, NOT 127.0.0.1/localhost.
  // If you're running on Chrome/web or Windows desktop, "localhost" works fine.
  // Set API_BASE_URL at build/run time for emulators, devices, and deployments.
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://localhost:5000/api",
  );
}
