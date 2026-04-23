import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../consumption/data/obd2/obd2_service.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/domain/entities/vin_data.dart';
import '../../../vehicle/presentation/widgets/vin_confirm_dialog.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../../vehicle/providers/vin_decoder_provider.dart';
import '../../providers/onboarding_obd2_connector.dart';
import '../../providers/onboarding_wizard_provider.dart';

/// Optional onboarding step (#816) that lets a new user connect their
/// OBD2 adapter, auto-read the VIN, decode it via the vPIC / WMI
/// fallback, and auto-fill the vehicle profile without any manual
/// entry.
///
/// Drives a small state machine via an internal [_Phase] enum —
/// initial → connecting → readingVin → done. All three possible
/// failure branches (picker cancel, VIN read null, connect error)
/// leave the phase on [_Phase.initial] so the user can retry or tap
/// "Maybe later" to skip to the manual vehicle step.
///
/// When the flow completes successfully with a [VinData.isComplete]
/// result and the user accepts the [VinConfirmDialog], the step saves
/// a pre-populated [VehicleProfile] directly via
/// [vehicleProfileListProvider] and invokes [onAutoFillSuccess] so the
/// wizard can advance past the manual vehicle step. When the user
/// modifies / cancels the dialog, or the VIN is only partially
/// decoded, the step just stashes the decoded data in the wizard
/// state and calls [onProceed] — the following manual step picks it
/// up from there.
class OnboardingObd2Step extends ConsumerStatefulWidget {
  /// Called when the user taps "Maybe later" or after a failed
  /// connect / VIN read so the wizard can advance to the next step
  /// (normally the manual vehicle step).
  final VoidCallback onProceed;

  /// Called when the step successfully saved a fully-populated
  /// [VehicleProfile] — the wizard should advance PAST the manual
  /// vehicle step so the user isn't asked to re-enter what we just
  /// decoded.
  final VoidCallback onAutoFillSuccess;

  const OnboardingObd2Step({
    super.key,
    required this.onProceed,
    required this.onAutoFillSuccess,
  });

  @override
  ConsumerState<OnboardingObd2Step> createState() =>
      _OnboardingObd2StepState();
}

enum _Phase { initial, connecting, readingVin }

class _OnboardingObd2StepState extends ConsumerState<OnboardingObd2Step> {
  static const _uuid = Uuid();

  _Phase _phase = _Phase.initial;

  Future<void> _onConnect() async {
    final l10n = AppLocalizations.of(context);
    final connector = ref.read(onboardingObd2ConnectorProvider);

    setState(() => _phase = _Phase.connecting);
    Obd2Service? service;
    try {
      service = await connector.connect(context);
    } catch (e) {
      debugPrint('OnboardingObd2Step: connect threw $e');
      service = null;
    }

    if (!mounted) return;

    if (service == null) {
      // User cancelled the picker, or the scan/connect failed. Surface
      // a non-blocking snackbar so the user can retry or tap the "Maybe
      // later" button — the skip path is still available below the
      // scaffold body.
      setState(() => _phase = _Phase.initial);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.onboardingObd2ConnectFailed ??
                "Couldn't connect to the adapter. You can retry or skip.",
          ),
        ),
      );
      return;
    }

    setState(() => _phase = _Phase.readingVin);

    String? vin;
    try {
      vin = await connector.readVin(service);
    } catch (e) {
      debugPrint('OnboardingObd2Step: readVin threw $e');
      vin = null;
    }

    if (!mounted) return;

    if (vin == null || vin.isEmpty) {
      // Adapter connected, but the car didn't hand back a VIN — older
      // ECUs / incompatible adapters. Stash a flag on the wizard state
      // so the manual step can surface a "Couldn't read VIN" banner.
      ref
          .read(onboardingWizardControllerProvider.notifier)
          .setObd2VinReadFailed();
      setState(() => _phase = _Phase.initial);
      widget.onProceed();
      return;
    }

    await _decodeAndConfirm(vin);
  }

  Future<void> _decodeAndConfirm(String vin) async {
    VinData? decoded;
    try {
      decoded = await ref.read(decodedVinProvider(vin).future);
    } catch (e) {
      debugPrint('OnboardingObd2Step: VIN decode failed: $e');
      decoded = null;
    }

    if (!mounted) return;
    setState(() => _phase = _Phase.initial);

    if (decoded == null || decoded.source == VinDataSource.invalid) {
      // The OBD2 adapter gave us a VIN but the decoder can't do
      // anything with it. Fall through to manual entry with the VIN
      // stashed so the following step can still pre-fill the VIN text
      // field if it wants to.
      ref.read(onboardingWizardControllerProvider.notifier).setObd2VinData(
            VinData(vin: vin, source: VinDataSource.invalid),
          );
      widget.onProceed();
      return;
    }

    // Stash the decoded data up-front so the manual fallback path also
    // sees it — matches the behaviour expected by the follow-up
    // vehicle-details step and keeps the state available for later
    // inspection / retries.
    ref
        .read(onboardingWizardControllerProvider.notifier)
        .setObd2VinData(decoded);

    final outcome = await VinConfirmDialog.show(context, decoded);
    if (!mounted) return;

    if (outcome != VinConfirmOutcome.confirm) {
      // User chose "Modify manually" — fall through to the manual
      // step with the VIN retained on the wizard state.
      widget.onProceed();
      return;
    }

    // Full auto-fill path: build a VehicleProfile from the decoded
    // VIN and save it directly so the manual step can be skipped
    // entirely.
    try {
      await _saveDecodedProfile(decoded);
    } catch (e) {
      debugPrint('OnboardingObd2Step: save decoded profile failed: $e');
    }
    if (!mounted) return;
    widget.onAutoFillSuccess();
  }

  Future<void> _saveDecodedProfile(VinData data) async {
    // vPIC returns displacement in litres but the profile stores it in
    // cubic centimetres so the speed-density fuel-rate math can pick
    // it up without round-trip unit conversion at query time.
    final engineDisplacementCc = data.displacementL != null
        ? (data.displacementL! * 1000).round()
        : null;

    // vPIC's GVWR is gross vehicle weight, not curb weight — approx
    // by subtracting a typical 400 kg payload on the edit screen; for
    // the onboarding flow we skip it and leave curb weight blank so
    // the user isn't surprised by an inaccurate number.
    final modelLabel = [
      if (data.modelYear != null) data.modelYear.toString(),
      if (data.make != null) data.make,
      if (data.model != null) data.model,
    ].whereType<String>().join(' ').trim();

    final profile = VehicleProfile(
      id: _uuid.v4(),
      // Default to the decoded Year Make Model so the vehicle list
      // shows something recognisable; the user can rename later.
      name: modelLabel.isEmpty ? 'My car' : modelLabel,
      type: VehicleType.combustion,
      preferredFuelType: _fuelTypeKeyFromVpic(data.fuelTypePrimary),
      vin: data.vin,
      engineDisplacementCc: engineDisplacementCc,
      engineCylinders: data.cylinderCount,
    );

    await ref.read(vehicleProfileListProvider.notifier).save(profile);
  }

  /// Map vPIC's free-text "Fuel Type - Primary" value to the app's
  /// internal fuel-type keys. vPIC returns labels like "Gasoline",
  /// "Diesel", "Electric" — we map the diesel branch explicitly so
  /// the speed-density fallback in [Obd2Service.readFuelRateLPerHour]
  /// picks up the right AFR / density later. Anything else defaults
  /// to "e10", matching the combustion vehicle section's default on
  /// the edit screen.
  static String? _fuelTypeKeyFromVpic(String? vpicValue) {
    final v = vpicValue?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    if (v.contains('diesel')) return 'diesel';
    if (v.contains('electric')) return null; // EV path not covered here
    return 'e10';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l10n?.onboardingObd2StepTitle ??
                  'Connect your OBD2 adapter',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.onboardingObd2StepBody ??
                "Plug your OBD2 adapter into the car's port and turn the "
                    "ignition on. We'll read the VIN and fill in engine "
                    'details for you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (_phase == _Phase.readingVin)
            Column(
              key: const Key('onboardingObd2ReadingVin'),
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  l10n?.onboardingObd2ReadingVin ?? 'Reading VIN…',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    key: const Key('onboardingObd2ConnectButton'),
                    onPressed: _phase == _Phase.connecting ? null : _onConnect,
                    icon: _phase == _Phase.connecting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bluetooth),
                    label: Text(
                      l10n?.onboardingObd2ConnectButton ?? 'Connect adapter',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('onboardingObd2SkipButton'),
                  onPressed:
                      _phase == _Phase.connecting ? null : widget.onProceed,
                  child: Text(
                    l10n?.onboardingObd2SkipButton ?? 'Maybe later',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
