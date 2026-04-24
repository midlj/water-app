import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/meter_reading_model.dart';

class MeterService {
  Future<MeterReadingModel> addReading(Map<String, dynamic> data) async {
    final response = await ApiClient.instance.post(ApiEndpoints.meter, data: data);
    return MeterReadingModel.fromJson(response.data['data']);
  }

  Future<List<MeterReadingModel>> getReadingsByUser(String userId, {int? year, int page = 1}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.readingsByUser(userId),
      queryParameters: {
        if (year != null) 'year': year,
        'page': page,
        'limit': 12,
      },
    );
    final list = response.data['data'] as List;
    return list.map((e) => MeterReadingModel.fromJson(e)).toList();
  }

  Future<List<MeterReadingModel>> getAllReadings({int? month, int? year, int page = 1}) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.allReadings,
      queryParameters: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        'page': page,
        'limit': 20,
      },
    );
    final list = response.data['data'] as List;
    return list.map((e) => MeterReadingModel.fromJson(e)).toList();
  }
}
