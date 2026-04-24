import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/payment_model.dart';

class PaymentService {
  Future<PaymentModel> makePayment(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(ApiEndpoints.payments, data: data);
    return PaymentModel.fromJson(response.data['data']);
  }

  Future<List<PaymentModel>> getPaymentsByUser(String userId, {int page = 1}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.paymentsByUser(userId),
      queryParameters: {'page': page, 'limit': 12},
    );
    final list = response.data['data'] as List;
    return list.map((e) => PaymentModel.fromJson(e)).toList();
  }

  Future<List<PaymentModel>> getAllPayments({int page = 1}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.allPayments,
      queryParameters: {'page': page, 'limit': 20},
    );
    final list = response.data['data'] as List;
    return list.map((e) => PaymentModel.fromJson(e)).toList();
  }
}
