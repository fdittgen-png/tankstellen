import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Pins the `Feature.paymentQrScan` and `Feature.communityPriceReports`
/// gates (#1638).
///
/// Both station-detail AppBar actions (scan payment QR, report price)
/// already shipped live and reachable; these flags bring them under
/// central feature management so they can be toggled per profile.
/// Default-on preserves current behaviour. The manifest contract is
/// what `StationDetailAppBarActions` checks via `enabledFeaturesProvider`.
void main() {
  const manifest = FeatureManifest.defaultManifest;

  for (final feature in [
    Feature.paymentQrScan,
    Feature.communityPriceReports,
  ]) {
    group('Feature.${feature.name} manifest entry', () {
      test('the default manifest declares an entry', () {
        final entry = manifest.entries[feature];
        expect(entry, isNotNull);
        expect(entry!.feature, feature);
      });

      test('is default-enabled — preserves the action being reachable', () {
        expect(manifest.entries[feature]!.defaultEnabled, isTrue);
        expect(manifest.defaultEnabledSet(), contains(feature));
      });

      test('has no prerequisites — it depends on nothing', () {
        expect(manifest.entries[feature]!.requires, isEmpty);
      });
    });
  }
}
