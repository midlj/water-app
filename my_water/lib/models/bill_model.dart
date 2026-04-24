class TariffBreakdown {
  final String tier;
  final double units;
  final double rate;
  final double amount;

  const TariffBreakdown({
    required this.tier,
    required this.units,
    required this.rate,
    required this.amount,
  });

  factory TariffBreakdown.fromJson(Map<String, dynamic> json) => TariffBreakdown(
        tier: json['tier'] ?? '',
        units: (json['units'] ?? 0).toDouble(),
        rate: (json['rate'] ?? 0).toDouble(),
        amount: (json['amount'] ?? 0).toDouble(),
      );
}

class BillModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? meterNumber;
  final String billNumber;
  final int month;
  final int year;
  final double previousReading;
  final double currentReading;
  final double unitsConsumed;
  final List<TariffBreakdown> tariffBreakdown;
  final double waterCharges;
  final double serviceCharge;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final DateTime dueDate;
  final DateTime? paidDate;
  final DateTime createdAt;

  const BillModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.meterNumber,
    required this.billNumber,
    required this.month,
    required this.year,
    required this.previousReading,
    required this.currentReading,
    required this.unitsConsumed,
    required this.tariffBreakdown,
    required this.waterCharges,
    required this.serviceCharge,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.dueDate,
    this.paidDate,
    required this.createdAt,
  });

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'unpaid' && dueDate.isBefore(DateTime.now());

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['userId'] is Map ? json['userId'] as Map : null;
    return BillModel(
      id: json['_id'] ?? '',
      userId: userObj?['_id'] ?? json['userId'] ?? '',
      userName: userObj?['name'],
      userEmail: userObj?['email'],
      meterNumber: userObj?['meterNumber'],
      billNumber: json['billNumber'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      previousReading: (json['previousReading'] ?? 0).toDouble(),
      currentReading: (json['currentReading'] ?? 0).toDouble(),
      unitsConsumed: (json['unitsConsumed'] ?? 0).toDouble(),
      tariffBreakdown: (json['tariffBreakdown'] as List? ?? [])
          .map((e) => TariffBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      waterCharges: (json['waterCharges'] ?? 0).toDouble(),
      serviceCharge: (json['serviceCharge'] ?? 5).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'unpaid',
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
