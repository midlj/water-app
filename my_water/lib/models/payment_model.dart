class PaymentModel {
  final String id;
  final String userId;
  final String? userName;
  final String billId;
  final String? billNumber;
  final String transactionId;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime paymentDate;
  final String? notes;

  const PaymentModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.billId,
    this.billNumber,
    required this.transactionId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['userId'] is Map ? json['userId'] as Map : null;
    final billObj = json['billId'] is Map ? json['billId'] as Map : null;
    return PaymentModel(
      id: json['_id'] ?? '',
      userId: userObj?['_id'] ?? json['userId'] ?? '',
      userName: userObj?['name'],
      billId: billObj?['_id'] ?? json['billId'] ?? '',
      billNumber: billObj?['billNumber'],
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'online',
      status: json['status'] ?? 'completed',
      paymentDate: DateTime.tryParse(json['paymentDate'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
    );
  }
}
