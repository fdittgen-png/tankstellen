import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/data/community_report_service.dart';

void main() {
  group('CommunityReportService.submitReport (#484)', () {
    test(
        'throws ArgumentError when neither reportedPrice nor correctionText '
        'is provided — mirrors the Supabase check constraint',
        () async {
      expect(
        () => CommunityReportService.submitReport(
          stationId: 'st-1',
          fuelType: 'e5',
          countryCode: 'FR',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when correctionText is an empty string',
        () async {
      expect(
        () => CommunityReportService.submitReport(
          stationId: 'st-1',
          fuelType: 'name',
          countryCode: 'FR',
          correctionText: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'returns normally in local-only mode (no supabaseClient) even with '
        'a valid price payload — the method is a no-op',
        () async {
      await expectLater(
        CommunityReportService.submitReport(
          stationId: 'st-1',
          fuelType: 'e5',
          countryCode: 'FR',
          reportedPrice: 1.799,
        ),
        completes,
      );
    });

    test(
        'returns normally in local-only mode with a valid metadata '
        'payload (correctionText only)',
        () async {
      await expectLater(
        CommunityReportService.submitReport(
          stationId: 'st-1',
          fuelType: 'name',
          countryCode: 'FR',
          correctionText: 'Shell Castelnau',
        ),
        completes,
      );
    });
  });
}
