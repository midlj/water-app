import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../core/network/api_client.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  List<PaymentModel> _payments = [];
  bool _loading = false;
  String? _error;
  String? _successMessage;

  List<PaymentModel> get payments => _payments;
  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadPaymentsByUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await _service.getPaymentsByUser(userId);
    } catch (e) {
      _error = ApiClient.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadAllPayments() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await _service.getAllPayments();
    } catch (e) {
      _error = ApiClient.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> makePayment(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final payment = await _service.makePayment(data);
      _payments.insert(0, payment);
      _successMessage = 'Payment of \$${payment.amount.toStringAsFixed(2)} successful!\nTxn: ${payment.transactionId}';
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
