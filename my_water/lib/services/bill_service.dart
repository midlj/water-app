import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/bill_model.dart';

class BillService {
  Future<BillModel> generateBill(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(ApiEndpoints.generateBill, data: data);
    return BillModel.fromJson(response.data['data']);
  }

  Future<List<BillModel>> getBillsByUser(String userId, {String? status, int? year, int page = 1}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.billsByUser(userId),
      queryParameters: {
        if (status != null) 'status': status,
        if (year != null) 'year': year,
        'page': page,
        'limit': 12,
      },
    );
    final list = response.data['data'] as List;
    return list.map((e) => BillModel.fromJson(e)).toList();
  }

  Future<List<BillModel>> getAllBills({String? status, int? month, int? year, int page = 1}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.allBills,
      queryParameters: {
        if (status != null) 'status': status,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        'page': page,
        'limit': 20,
      },
    );
    final list = response.data['data'] as List;
    return list.map((e) => BillModel.fromJson(e)).toList();
  }

  Future<BillModel> getBillById(String id) async {
    final response = await ApiClient.instance.get(ApiEndpoints.billById(id));
    return BillModel.fromJson(response.data['data']);
  }
}
