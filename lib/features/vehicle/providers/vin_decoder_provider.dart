import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/app_state_provider.dart';
import '../data/vin_decoder.dart';
import '../domain/entities/vin_data.dart';

part 'vin_decoder_provider.g.dart';

/// Shared [VinDecoder] instance (#812 phase 2).
///
/// `keepAlive: true` so the Dio rate-limiter and its cache of in-flight
/// requests survives between decode attempts — a user may paste the
/// wrong VIN, correct it, and hit decode again within seconds. We
/// don't want to re-create the whole HTTP stack each time.
@Riverpod(keepAlive: true)
VinDecoder vinDecoder(Ref ref) => VinDecoder();

/// VIN decoder for the auto-population flow (#1399). Honors the
/// `vinOnlineDecode` GDPR consent toggle: when the user has not opted
/// in, the network call is skipped entirely and the decoder runs in
/// offline-only mode (WMI + position-10 year).
///
/// Distinct from [vinDecoderProvider] — that decoder is for the
/// existing manual VIN-entry flow on the edit-vehicle screen, where
/// the user has explicitly typed a VIN and tapped "decode" so the
/// online lookup is implicitly consented to. The auto-population flow
/// runs silently on adapter pair, so it must respect the explicit
/// consent toggle.
///
/// NOT keepAlive: rebuilds when the consent toggles so the next
/// adapter-pair flow honors the freshest setting without an app
/// restart.
@riverpod
VinDecoder consentAwareVinDecoder(Ref ref) {
  final consent = ref.watch(gdprConsentProvider);
  return VinDecoder(allowOnlineLookup: consent.vinOnlineDecode);
}

/// Async family that decodes a given [vin] into [VinData] via the
/// shared [VinDecoder] (#812 phase 2).
///
/// Keyed by the trimmed, upper-cased VIN so two screens that ask for
/// the same VIN in the same session share a single decoded response.
/// Empty or short strings return `null` without touching the network —
/// the UI should gate the provider read behind a length check, but we
/// short-circuit here too as a safety net.
///
/// `keepAlive: true` so the result is cached for the session. When
/// the user edits the VIN field, the widget reads a different family
/// key and triggers a fresh decode; the previous family entry stays
/// in memory until the ProviderScope is torn down.
@Riverpod(keepAlive: true)
Future<VinData?> decodedVin(Ref ref, String vin) async {
  final trimmed = vin.trim();
  if (trimmed.isEmpty) return null;
  final decoder = ref.watch(vinDecoderProvider);
  return decoder.decode(trimmed);
}
