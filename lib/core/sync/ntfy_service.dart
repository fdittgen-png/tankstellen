import 'package:dio/dio.dart';

import '../services/dio_factory.dart';

/// Client for ntfy.sh push notification service.
/// Used when TankSync is connected and user opts into real-time push.
class NtfyService {
  static const _baseUrl = 'https://ntfy.sh';
  final Dio _dio;

  NtfyService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  /// Subscribe to a topic (generate unique per user).
  String generateTopic(String userId) => 'tankstellen-$userId';

  /// Send a test notification to verify the topic works.
  Future<bool> sendTestNotification(String topic) async {
    try {
      await _dio.post(
        '$_baseUrl/$topic',
        data: 'TankSync connected! You will receive price alerts here.',
        options: Options(headers: {
          'Title': 'TankSync Test',
          'Tags': 'fuelpump,white_check_mark',
          'Priority': '3',
        }),
      );
      return true;
    } on DioException {
      return false;
    }
  }

  /// Send a price alert notification.
  Future<void> sendPriceAlert({
    required String topic,
    required String stationName,
    required String fuelType,
    required double currentPrice,
    required double targetPrice,
  }) async {
    await _dio.post(
      '$_baseUrl/$topic',
      data:
          '$fuelType at $stationName dropped to \u20ac${currentPrice.toStringAsFixed(3)} (target: \u20ac${targetPrice.toStringAsFixed(3)})',
      options: Options(headers: {
        'Title': 'Price Alert: $stationName',
        'Tags': 'fuelpump,chart_with_downwards_trend',
        'Priority': '4',
      }),
    );
  }
}
