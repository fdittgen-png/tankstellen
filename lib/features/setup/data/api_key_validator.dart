import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/dio_factory.dart';

/// Result of an API key validation attempt.
class ApiKeyValidationResult {
  final bool isValid;
  final String? errorMessage;
  const ApiKeyValidationResult({required this.isValid, this.errorMessage});
}

/// Validates Tankerkoenig API keys by format check and minimal test request.
class ApiKeyValidator {
  final Dio _dio;

  /// UUID v4 format: 8-4-4-4-12 hexadecimal characters.
  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Returns `true` when [key] matches UUID format (8-4-4-4-12 hex chars).
  static bool isValidUuidFormat(String key) => _uuidRegex.hasMatch(key.trim());

  ApiKeyValidator({Dio? dio})
      : _dio = dio ?? DioFactory.create(baseUrl: ApiConstants.baseUrl);

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
    } on DioException catch (e, st) { // ignore: unused_catch_stack
      return ApiKeyValidationResult(
        isValid: false,
        errorMessage: e.message ?? 'Network error',
      );
    }
  }
}
