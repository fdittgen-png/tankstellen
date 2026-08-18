// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';

/// #3320 (Epic #3314) — facade over the Android Companion-Device-Manager
/// association with the OBD2 dongle.
///
/// A CDM association grants `REQUEST_COMPANION_START_FOREGROUND_SERVICES_FROM
/// _BACKGROUND` — the documented exemption that lets the native
/// `CompanionPresenceService` start the `connectedDevice`
/// `AutoRecordForegroundService` from the background when the paired dongle
/// appears, WITHOUT `ACCESS_BACKGROUND_LOCATION`. So a hands-free trip can
/// begin the moment the car's dongle powers up.
///
/// Behind an interface so the [CompanionAutoRecordCoordinator] is unit-testable
/// without the platform channel. Android-only + API 34+; every method degrades
/// to a safe `false` on an unsupported platform (the channel throws
/// `MissingPluginException` on iOS / pre-34, caught here).
abstract class CompanionDeviceAssociation {
  /// Whether CDM association is available (Android 34+ with the CDM feature).
  Future<bool> isSupported();

  /// Whether we already hold an association for the dongle.
  Future<bool> isAssociated();

  /// Launch the system association dialog for the dongle at [mac]. Must be
  /// called from the foreground (it shows an Activity dialog). Returns true
  /// once the user confirms.
  Future<bool> associate(String mac);

  /// Drop all of our associations.
  Future<bool> disassociate();
}

class MethodChannelCompanionDeviceAssociation
    implements CompanionDeviceAssociation {
  const MethodChannelCompanionDeviceAssociation();

  static const MethodChannel _channel =
      MethodChannel('tankstellen/auto_record/cdm');

  @override
  Future<bool> isSupported() => _callBool('isSupported');

  @override
  Future<bool> isAssociated() => _callBool('isAssociated');

  @override
  Future<bool> associate(String mac) =>
      _callBool('associate', <String, Object?>{'mac': mac});

  @override
  Future<bool> disassociate() => _callBool('disassociate');

  Future<bool> _callBool(String method, [Map<String, Object?>? args]) async {
    try {
      return (await _channel.invokeMethod<bool>(method, args)) ?? false;
    } on MissingPluginException {
      // iOS / pre-34 / default builds without the channel registered.
      return false;
    } on PlatformException {
      return false;
    }
  }
}
