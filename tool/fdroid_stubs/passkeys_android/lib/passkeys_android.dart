// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:passkeys_platform_interface/passkeys_platform_interface.dart';
import 'package:passkeys_platform_interface/types/types.dart';

/// Libre / F-Droid no-op Android implementation of [PasskeysPlatform] (#3478).
///
/// Endorses `passkeys` for Android as a Dart-only impl (no native plugin), so
/// the federated plugin resolves and Supabase compiles, but no GMS FIDO/auth
/// code reaches the fdroid dex. Passkey auth is unavailable on the libre build;
/// the app never invokes it (TankSync uses email/anon), so the operations
/// throw [UnsupportedError] and [getAvailability] reports no support.
class PasskeysAndroid extends PasskeysPlatform {
  /// Registered by the generated plugin registrant on the libre build.
  static void registerWith() => PasskeysPlatform.instance = PasskeysAndroid();

  static Never _unsupported() => throw UnsupportedError(
        'Passkeys are unavailable on the libre / F-Droid build (no GMS FIDO).',
      );

  @override
  // ignore: deprecated_member_override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async =>
      _unsupported();

  @override
  Future<AuthenticateResponseType> authenticate(
    AuthenticateRequestType request,
  ) async =>
      _unsupported();

  @override
  Future<void> cancelCurrentAuthenticatorOperation() async {}

  @override
  Future<AvailabilityType> getAvailability() async => AvailabilityTypeAndroid(
        hasPasskeySupport: false,
        isNative: false,
        isUserVerifyingPlatformAuthenticatorAvailable: false,
      );
}
