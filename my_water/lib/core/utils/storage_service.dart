import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
    webOptions: WebOptions(
      dbName: 'water_bill_db',
      publicKey: 'water_bill_key',
    ),
  );

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> saveUserData(String json) async {
    await _storage.write(key: AppConstants.userKey, value: json);
  }

  static Future<String?> getUserData() async {
    return _storage.read(key: AppConstants.userKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
