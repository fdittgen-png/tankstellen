// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/features/consumption/domain/entities/recording_profile.dart';
import 'package:tankstellen/features/consumption/providers/recording_profile_provider.dart';

class _FixedProfile extends RecordingProfileController {
  _FixedProfile(this._profile);
  final RecordingProfile _profile;

  @override
  RecordingProfile build() => _profile;

  @override
  RecordingProfile effectiveFor(String? vehicleId) => _profile;
}

/// Pins the recording profile so a screen test is deterministic regardless of
/// the global default. Defaults to **auto-pin OFF** — the pre-#2785 behaviour
/// most trip-recording screen tests were written against (no auto-pin on
/// mount). Pass an explicit profile to exercise the auto-pin path. Typed
/// the riverpod `Override` (typed `dynamic` so it drops into either a
/// `pumpApp` `List<Object>` or a bare `ProviderScope(overrides: [...])`
/// `List<Override>` without importing the un-exported `Override` name).
dynamic recordingProfileOverride([
  RecordingProfile profile = const RecordingProfile(autoPin: false),
]) =>
    recordingProfileControllerProvider
        .overrideWith(() => _FixedProfile(profile));
