import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../services/bill_service.dart';
import '../core/network/api_client.dart';

class BillProvider extends ChangeNotifier {
  final BillService _service = BillService();

  List<BillModel> _bills = [];
  bool _loading = false;
  String? _error;
  String? _successMessage;

  List<BillModel> get bills => _bills;
  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadBillsByUser(String userId, {String? status, int? year}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bills = await _service.getBillsByUser(userId, status: status, year: year);
    } catch (e) {
      _error = ApiClient.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadAllBills({String? status, int? month, int? year}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bills = await _service.getAllBills(status: status, month: month, year: year);
    } catch (e) {
      _error = ApiClient.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> generateBill(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final bill = await _service.generateBill(data);
      _bills.insert(0, bill);
      _successMessage = 'Bill ${bill.billNumber} generated. Amount: \$${bill.totalAmount.toStringAsFixed(2)}';
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

  void markBillPaid(String billId) {
    final idx = _bills.indexWhere((b) => b.id == billId);
    if (idx != -1) {
      // Reload to reflect updated status
      notifyListeners();
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
