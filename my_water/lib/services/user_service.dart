import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class UserService {
  Future<List<UserModel>> getAllUsers({String? role, String? search, int page = 1}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.users,
      queryParameters: {
        if (role != null) 'role': role,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': 20,
      },
    );
    final list = response.data['data'] as List;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> getUserById(String id) async {
    final response = await ApiClient.instance.get(ApiEndpoints.userById(id));
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(ApiEndpoints.users, data: data);
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.instance.put(ApiEndpoints.userById(id), data: data);
    return UserModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await ApiClient.instance.get(ApiEndpoints.dashboardStats);
    return response.data['data'] as Map<String, dynamic>;
  }
}
