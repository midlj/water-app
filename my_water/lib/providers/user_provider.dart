import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../core/network/api_client.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();

  List<UserModel> _users = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String? _error;

  List<UserModel> get users => _users;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadUsers({String? role, String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _service.getAllUsers(role: role, search: search);
    } catch (e) {
      _error = ApiClient.parseError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadStats() async {
    try {
      _stats = await _service.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      final user = await _service.createUser(data);
      _users.insert(0, user);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateUser(id, data);
      final idx = _users.indexWhere((u) => u.id == id);
      if (idx != -1) {
        _users[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
