import 'package:flutter/material.dart';
import '../models/meter_reading_model.dart';
import '../services/meter_service.dart';
import '../core/network/api_client.dart';

class MeterProvider extends ChangeNotifier {
  final MeterService _service = MeterService();

  List<MeterReadingModel> _readings = [];
  bool _loading = false;
  String? _error;
  String? _successMessage;

  List<MeterReadingModel> get readings => _readings;
  bool get loading => _loading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadReadings(String userId, {int? year}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _readings = await _service.getReadingsByUser(userId, year: year);
    } catch (e) {
      _error = ApiClient.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> addReading(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final reading = await _service.addReading(data);
      _readings.insert(0, reading);
      _successMessage = 'Reading recorded. Units consumed: ${reading.unitsConsumed}';
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
