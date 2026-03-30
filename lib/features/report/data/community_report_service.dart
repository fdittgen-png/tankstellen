import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for submitting and retrieving community price reports.
class CommunityReportService {
  /// Submit a price report.
  /// If TankSync is connected, sends to Supabase.
  /// If Germany and API key available, also sends to Tankerkoenig
  /// (handled separately by report_screen.dart).
  static Future<void> submitReport({
    required String stationId,
    required String fuelType,
    required double reportedPrice,
    required String countryCode,
    String? supabaseUserId,
    SupabaseClient? supabaseClient,
  }) async {
    // If Supabase connected, insert into price_reports table
    if (supabaseClient != null && supabaseUserId != null) {
      await supabaseClient.from('price_reports').insert({
        'reporter_id': supabaseUserId,
        'station_id': stationId,
        'country_code': countryCode,
        'fuel_type': fuelType,
        'reported_price': reportedPrice,
      });
    }
    // For Germany, the existing Tankerkoenig complaint endpoint
    // is already handled by report_screen.dart
  }

  /// Get recent community reports for a station (last 2 hours).
  static Future<List<Map<String, dynamic>>> getReports({
    required String stationId,
    required SupabaseClient client,
  }) async {
    final response = await client
        .from('price_reports')
        .select()
        .eq('station_id', stationId)
        .gte('reported_at',
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String())
        .order('reported_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
