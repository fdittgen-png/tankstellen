import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../consumption/data/obd2/elm327_protocol.dart';
import '../../consumption/data/obd2/obd2_service.dart';
import '../../consumption/presentation/widgets/obd2_adapter_picker.dart';

part 'onboarding_obd2_connector.g.dart';

/// Narrow seam that the OBD2 onboarding step (#816) uses to talk to the
/// adapter stack.
///
/// Production implementation drives [showObd2AdapterPicker] to open
/// the existing scan → pick → connect bottom sheet (#743) and then
/// issues Mode 09 PID 02 (`0902`) to read the VIN. Widget tests swap
/// this out for a fake so the onboarding flow can be exercised without
/// a Bluetooth stack — the existing `Obd2ConnectionService` seam sits
/// one layer below and isn't ergonomic for a three-branch happy-path
/// test (connect + VIN success / VIN null / connect failure).
///
/// #1310 — `connect` now exposes the picked MAC alongside the live
/// service so the onboarding step can persist [VehicleProfile.pairedAdapterMac]
/// on the freshly-saved profile. Without this, users who finished the
/// adapter-first onboarding ended up with a profile that had a service
/// connection at runtime but no `pairedAdapterMac` — the auto-record
/// orchestrator silently dropped them.
abstract class OnboardingObd2Connector {
  /// Open the adapter picker and return the connected session
  /// (service + MAC), or `null` when the user cancels / the scan
  /// fails. The MAC stored on the result is what the onboarding step
  /// writes to [VehicleProfile.pairedAdapterMac] (#1310).
  Future<OnboardingObd2Session?> connect(BuildContext context);

  /// Read the VIN from [service] via Mode 09 PID 02. Returns `null`
  /// when the car doesn't answer (older ECUs that don't implement the
  /// PID, or a flaky adapter that times out).
  Future<String?> readVin(Obd2Service service);
}

/// Result of [OnboardingObd2Connector.connect] — the live service plus
/// the MAC the user picked. The MAC is the stable identifier the
/// auto-record orchestrator and the pinned-MAC fast path key on; we
/// surface it here (#1310) so the onboarding step can persist it
/// without poking inside [Obd2Service].
class OnboardingObd2Session {
  /// Live OBD2 connection ready for VIN/PID reads.
  final Obd2Service service;

  /// MAC address (BLE) or device id (Classic) of the adapter the user
  /// just paired. Empty string is treated as "unknown" by callers —
  /// production picker always supplies a non-empty id.
  final String mac;

  const OnboardingObd2Session({required this.service, required this.mac});
}

/// Default [OnboardingObd2Connector] — wires the existing adapter
/// picker + [Obd2Service.sendCommand] into a single pair of methods.
class DefaultOnboardingObd2Connector implements OnboardingObd2Connector {
  const DefaultOnboardingObd2Connector();

  @override
  Future<OnboardingObd2Session?> connect(BuildContext context) async {
    // #1310 — use the connect-and-pick variant so we can thread the
    // MAC back to the onboarding step. During onboarding the active
    // vehicle does not exist yet, so the picker's own
    // `_persistPickedAdapterToActiveVehicle` no-ops and we have to
    // persist the MAC ourselves on the profile being created.
    final picked = await showObd2AdapterPickerWithMac(context);
    if (picked == null) return null;
    return OnboardingObd2Session(service: picked.service, mac: picked.mac);
  }

  @override
  Future<String?> readVin(Obd2Service service) async {
    try {
      final raw = await service.sendCommand(Elm327Protocol.vinCommand);
      return Elm327Protocol.parseVin(raw);
    } catch (e, st) {
      debugPrint('OnboardingObd2Connector.readVin failed: $e\n$st');
      return null;
    }
  }
}

/// Keep-alive so the default instance survives across onboarding step
/// rebuilds — the connector itself is stateless, but tests override
/// this provider with a stateful fake that must outlive the step's
/// `setState` calls.
@Riverpod(keepAlive: true)
OnboardingObd2Connector onboardingObd2Connector(Ref ref) =>
    const DefaultOnboardingObd2Connector();
