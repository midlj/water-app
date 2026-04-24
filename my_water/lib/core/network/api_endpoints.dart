class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Users
  static const String users = '/users';
  static const String dashboardStats = '/users/dashboard/stats';
  static String userById(String id) => '/users/$id';

  // Meter
  static const String meter = '/meter';
  static const String allReadings = '/meter';
  static String readingsByUser(String userId) => '/meter/$userId';

  // Bills
  static const String generateBill = '/bills/generate';
  static const String allBills = '/bills';
  static String billsByUser(String userId) => '/bills/user/$userId';
  static String billById(String id) => '/bills/$id';
  static String updateBillStatus(String id) => '/bills/$id/status';

  // Payments
  static const String payments = '/payments';
  static const String allPayments = '/payments';
  static String paymentsByUser(String userId) => '/payments/user/$userId';
  static String paymentById(String id) => '/payments/$id';
}
