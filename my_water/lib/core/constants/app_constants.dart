class AppConstants {
  AppConstants._();

  static const String appName = 'WaterBill';
  // localhost for Windows desktop / web; use 10.0.2.2 for Android emulator
  static const String baseUrl = 'http://localhost:5001/api';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Month names
  static const List<String> months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  static String monthName(int month) => months[month - 1];
}
