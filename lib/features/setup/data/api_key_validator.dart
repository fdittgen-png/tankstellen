import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

/// Result of an API key validation attempt.
class ApiKeyValidationResult {
  final bool isValid;
  final String? errorMessage;
  const ApiKeyValidationResult({required this.isValid, this.errorMessage});
}

/// Validates Tankerkoenig API keys by making a minimal test request.
class ApiKeyValidator {
  final Dio _dio;

  ApiKeyValidator({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<ApiKeyValidationResult> validate(String apiKey) async {
    try {
      final response = await _dio.get('/list.php', queryParameters: {
        'lat': ApiConstants.testLatitude,
        'lng': ApiConstants.testLongitude,
        'rad': 1,
        'type': 'e10',
        'apikey': apiKey,
      });
      if (response.data is Map && response.data['ok'] != true) {
        return ApiKeyValidationResult(
          isValid: false,
          errorMessage:
              response.data['message']?.toString() ?? 'Invalid API key',
        );
      }
      return const ApiKeyValidationResult(isValid: true);
    } on DioException catch (e) {
      return ApiKeyValidationResult(
        isValid: false,
        errorMessage: e.message ?? 'Network error',
      );
    }
  }
}
