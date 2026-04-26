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
abstract class OnboardingObd2Connector {
  /// Open the adapter picker and return a connected [Obd2Service], or
  /// `null` when the user cancels / the scan fails.
  Future<Obd2Service?> connect(BuildContext context);

  /// Read the VIN from [service] via Mode 09 PID 02. Returns `null`
  /// when the car doesn't answer (older ECUs that don't implement the
  /// PID, or a flaky adapter that times out).
  Future<String?> readVin(Obd2Service service);
}

/// Default [OnboardingObd2Connector] — wires the existing adapter
/// picker + [Obd2Service.sendCommand] into a single pair of methods.
class DefaultOnboardingObd2Connector implements OnboardingObd2Connector {
  const DefaultOnboardingObd2Connector();

  @override
  Future<Obd2Service?> connect(BuildContext context) =>
      showObd2AdapterPicker(context);

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
