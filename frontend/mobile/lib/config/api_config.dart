class ApiConfig {
  // Android emulator -> host machine's localhost is 10.0.2.2, NOT 127.0.0.1/localhost.
  // If you're running on Chrome/web or Windows desktop, "localhost" works fine.
  // If you're on a real Android phone on the same Wi-Fi as your PC, use your PC's LAN IP instead.
  static const String baseUrl = "http://localhost:5000/api";

  // Uncomment this line instead if you're testing on Chrome or Windows desktop:
  // static const String baseUrl = "http://localhost:5000/api";
}
