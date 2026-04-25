import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../domain/entities/report_type.dart';

/// Snapshot of which reporting backends are currently usable for the
/// active country / config. Pulled out of `report_screen.dart` in #563
/// to keep the screen file under the 300-LOC budget.
///
/// #484 — backend availability is computed up front so we can both
/// (a) render the no-backend banner and (b) disable the submit button
/// in the same condition. Keeping the UI consistent with what the
/// submit handler actually does.
class ReportBackendAvailability {
  ReportBackendAvailability({
    required this.canSubmitTankerkoenig,
    required this.canSubmitTankSync,
    required this.visibleTypes,
  });

  final bool canSubmitTankerkoenig;
  final bool canSubmitTankSync;
  final List<ReportType> visibleTypes;

  bool get hasAnyBackend => canSubmitTankerkoenig || canSubmitTankSync;

  bool get allVisibleRouteToGitHub =>
      visibleTypes.every((t) => t.routesToGitHub);

  /// #508 — GitHub-routed types (wrongName / wrongAddress) need no
  /// backend at all — the reporter opens the consent dialog and hands
  /// off to the browser. So the radio row and submit button are always
  /// usable when such a type is selected, regardless of Tankerkoenig
  /// or TankSync availability.
  bool selectedIsGitHubRouted(ReportType? selected) =>
      selected != null && selected.routesToGitHub;

  static ReportBackendAvailability watch(WidgetRef ref) {
    final country = ref.watch(activeCountryProvider);
    final apiKey = ref.watch(apiKeyStorageProvider).getApiKey();
    final syncConfig = ref.watch(syncStateProvider);
    final canSubmitTankerkoenig =
        country.code == 'DE' && apiKey != null && apiKey.isNotEmpty;
    final canSubmitTankSync =
        TankSyncClient.isConnected && syncConfig.userId != null;
    return ReportBackendAvailability(
      canSubmitTankerkoenig: canSubmitTankerkoenig,
      canSubmitTankSync: canSubmitTankSync,
      visibleTypes: ReportType.visibleForCountry(country.code),
    );
  }
}
