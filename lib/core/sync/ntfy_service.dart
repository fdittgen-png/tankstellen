import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/dio_factory.dart';

/// Outcome of an ntfy.sh POST. Carries enough detail to debug a
/// silent-no-notification case from the in-app error-log export
/// (#2001): the HTTP status, a one-line reason, and the topic the
/// caller hit. `success` is true only when the server replied 200.
@immutable
class NtfyPostResult {
  final bool success;
  final int? statusCode;
  final String reason;
  final String topic;

  const NtfyPostResult({
    required this.success,
    required this.topic,
    this.statusCode,
    this.reason = '',
  });

  @override
  String toString() =>
      'NtfyPostResult(success=$success, status=$statusCode, '
      'topic=$topic, reason=$reason)';
}

/// Client for ntfy.sh push notification service.
/// Used when TankSync is connected and user opts into real-time push.
class NtfyService {
  static const _baseUrl = 'https://ntfy.sh';
  final Dio _dio;

  // Push notifications are user-action triggered (alert firing or test
  // dispatch); rate-limiting them would defeat the point.
  NtfyService({Dio? dio}) : _dio = dio ?? DioFactory.create(rateLimit: null);

  /// Subscribe to a topic (generate unique per user).
  String generateTopic(String userId) => 'tankstellen-$userId';

  /// Send a test notification to verify the topic works.
  ///
  /// #2001 — returns a structured [NtfyPostResult] instead of a bare
  /// `bool` so the foreground setup card can surface the actual HTTP
  /// status / reason on failure ("ntfy responded with 429" rather than
  /// a generic "test failed" snack). The legacy `bool` callers can
  /// just check `.success`.
  Future<NtfyPostResult> sendTestNotification(String topic) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/$topic',
        data: 'TankSync connected! You will receive price alerts here.',
        options: Options(headers: {
          'Title': 'TankSync Test',
          'Tags': 'fuelpump,white_check_mark',
          'Priority': '3',
        }),
      );
      final ok = response.statusCode == 200;
      final result = NtfyPostResult(
        success: ok,
        statusCode: response.statusCode,
        topic: topic,
        reason: ok ? 'ok' : 'unexpected status ${response.statusCode}',
      );
      debugPrint('NtfyService.sendTestNotification: $result');
      return result;
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final reason = e.message ?? e.type.name;
      debugPrint(
        'NtfyService.sendTestNotification failed '
        '(topic=$topic, status=$status, type=${e.type.name}): $reason\n$st',
      );
      return NtfyPostResult(
        success: false,
        statusCode: status,
        topic: topic,
        reason: reason,
      );
    }
  }

  /// Send a price alert notification.
  ///
  /// #2001 — debugPrints topic + status + body length on the success
  /// path so `flutter logs` carries a positive confirmation, not just
  /// silence. Failure paths throw (the background-service caller
  /// catches + spools the error for the privacy dashboard).
  Future<void> sendPriceAlert({
    required String topic,
    required String stationName,
    required String fuelType,
    required double currentPrice,
    required double targetPrice,
  }) async {
    final data =
        '$fuelType at $stationName dropped to €${currentPrice.toStringAsFixed(3)} (target: €${targetPrice.toStringAsFixed(3)})';
    debugPrint(
      'NtfyService.sendPriceAlert: POST $_baseUrl/$topic '
      '(payload ${data.length} bytes)',
    );
    final response = await _dio.post(
      '$_baseUrl/$topic',
      data: data,
      options: Options(headers: {
        'Title': 'Price Alert: $stationName',
        'Tags': 'fuelpump,chart_with_downwards_trend',
        'Priority': '4',
      }),
    );
    debugPrint(
      'NtfyService.sendPriceAlert: status=${response.statusCode}, '
      'topic=$topic',
    );
  }
}
