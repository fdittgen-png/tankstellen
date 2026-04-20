import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import 'dio_factory.dart';

/// Result of submitting a price/status complaint to the Tankerkoenig API.
class ReportResult {
  final bool success;
  final String? message;

  const ReportResult({required this.success, this.message});
}

/// Service for submitting price/status complaints to the Tankerkoenig API.
///
/// Replaces the raw Dio call that was previously in report_screen.dart,
/// routing through DioFactory for consistent configuration and providing
/// typed exceptions for error handling.
class ReportService {
  final Dio _dio;

  ReportService()
      : _dio = DioFactory.create(
          baseUrl: ApiConstants.baseUrl,
          // User-triggered single submission — opt out of the default
          // rate limiter so the form doesn't appear to hang.
          rateLimit: null,
        );

  /// Visible for testing — accepts a custom Dio instance.
  ReportService.withDio(this._dio);

  /// Submit a complaint to the Tankerkoenig API.
  ///
  /// [stationId] — the Tankerkoenig station UUID.
  /// [reportType] — the API value for the report type (e.g. 'wrongDiesel').
  /// [apiKey] — the user's Tankerkoenig API key.
  /// [correction] — optional corrected price (required for price reports).
  Future<ReportResult> submitComplaint({
    required String stationId,
    required String reportType,
    required String? apiKey,
    double? correction,
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw const ApiException(message: 'API key required');
    }

    try {
      final response = await _dio.post(
        ApiConstants.complaintEndpoint,
        data: {
          'id': stationId,
          'type': reportType,
          'correction': ?correction,
          'apikey': apiKey,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['ok'] == true) {
        return ReportResult(
          success: true,
          message: data['message']?.toString(),
        );
      }

      return ReportResult(
        success: true,
        message: data is Map ? data['message']?.toString() : null,
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error submitting report',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
