import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/field_names.dart';

/// Service for submitting and retrieving community price reports.
class CommunityReportService {
  /// Submit a community report. Handles two shapes:
  ///
  ///  * **Price report** — `reportedPrice` is non-null, `correctionText`
  ///    is null. `fuelType` is the fuel code (`e5`, `e10`, `diesel`,
  ///    `e85`, `e98`, `lpg`).
  ///  * **Metadata report** (#484) — `reportedPrice` is null,
  ///    `correctionText` is the user-supplied new value. `fuelType`
  ///    doubles as the correction field identifier (`name`, `address`,
  ///    `status_open`, `status_closed`).
  ///
  /// The Supabase migration `20260414000001_report_metadata_fields.sql`
  /// makes `reported_price` nullable and adds a `correction_text`
  /// column, plus a check constraint that at least one of the two is
  /// set. This method enforces the same invariant client-side so we
  /// never hit the DB with an empty payload.
  ///
  /// If Germany and API key available, the Tankerkoenig complaint
  /// endpoint is handled separately by report_screen.dart.
  static Future<void> submitReport({
    required String stationId,
    required String fuelType,
    required String countryCode,
    double? reportedPrice,
    String? correctionText,
    String? supabaseUserId,
    SupabaseClient? supabaseClient,
  }) async {
    // Client-side guard matching the DB check constraint.
    if (reportedPrice == null && (correctionText == null || correctionText.isEmpty)) {
      throw ArgumentError(
        'CommunityReportService.submitReport requires either '
        'reportedPrice or correctionText to be set — the Supabase '
        'check constraint rejects rows with neither.',
      );
    }

    if (supabaseClient != null && supabaseUserId != null) {
      await supabaseClient.from(SyncFields.reportsTable).insert({
        SyncFields.reporterId: supabaseUserId,
        SyncFields.stationId: stationId,
        SyncFields.countryCode: countryCode,
        SyncFields.fuelType: fuelType,
        SyncFields.reportedPrice: ?reportedPrice,
        if (correctionText != null && correctionText.isNotEmpty)
          SyncFields.correctionText: correctionText.trim(),
      });
    }
  }

  /// Get recent community reports for a station (last 2 hours).
  static Future<List<Map<String, dynamic>>> getReports({
    required String stationId,
    required SupabaseClient client,
  }) async {
    final response = await client
        .from(SyncFields.reportsTable)
        .select()
        .eq(SyncFields.stationId, stationId)
        .gte(SyncFields.reportedAt,
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String())
        .order(SyncFields.reportedAt, ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
