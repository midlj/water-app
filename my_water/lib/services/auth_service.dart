import 'dart:convert';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.instance.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    await StorageService.saveToken(data['token']);
    await StorageService.saveUserData(jsonEncode(data['user']));
    return data;
  }

  Future<UserModel> getMe() async {
    final response = await ApiClient.instance.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data['user']);
  }

  Future<void> logout() async {
    await StorageService.clearAll();
  }

  Future<UserModel?> loadCachedUser() async {
    final json = await StorageService.getUserData();
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json));
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    return token != null;
  }
}
