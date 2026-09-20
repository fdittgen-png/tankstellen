// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4352 / Epic #4351 — the **protection contract**: what native execution
/// protection a recording session actually holds, on *this* artifact.
///
/// ## Why a contract before any implementation
///
/// The user report behind #4351 is "recording only works while its form is
/// open". The first cause is not Dart code at all — it is the **artifact**.
/// [kGpsRecordingForegroundServiceEnabled] is a compile-time
/// `bool.fromEnvironment('FGS_FORM_APPROVED')` define, and the release
/// workflows pass it only when the repository variable `FGS_FORM_APPROVED`
/// is set. It is **not** set, so today:
///
///   * the **Play** artifact ships with **no** foreground-service define and
///     no `FOREGROUND_SERVICE*` permission in its merged manifest — geolocator
///     is handed a `null` `ForegroundNotificationConfig` and the position
///     stream is owned by the Activity, which the OS destroys on a
///     backgrounded, screen-off process;
///   * the **F-Droid** and **dev** APKs ship the define **on** and the
///     `*FgsApproved` manifest overlay with it.
///
/// Two artifacts from one commit with different background capability is
/// exactly the fact this contract exists to make visible. The maintainer's
/// decision for the programme is **build it and disclose honestly**: an
/// artifact that cannot protect a recording must say so rather than dying
/// silently. This file is the machine-readable half of that disclosure; S5
/// (#4352c) owns the words, and no UI lives here.
///
/// ## The shape
///
///   * [RecordingSourceMode] — what the session is actually acquiring, which
///     decides which foreground-service *type* (and therefore which
///     type-specific permission) a protection owner may request. "No
///     unnecessary location collection to keep OBD2 alive" is enforced by
///     making the mode an input, not an assumption.
///   * [RecordingProtectionVerdict] — the six terminal answers. Only
///     [RecordingProtectionVerdict.acknowledged] means the OS accepted a
///     promotion for this session. **Unknown is not ready.**
///   * [RecordingProtectionStatus] — a verdict plus a typed
///     [RecordingProtectionReason], the `sessionGeneration` it was issued
///     for, and an optional diagnostic `detail`. Generation is what makes a
///     late native acknowledgement after Stop refusable rather than a
///     resurrection (#4344's fence, reused not copied).
///   * `RecordingProtectionOwner` (in `recording_protection_owner.dart`) —
///     the platform seam, with the `acquireProtection` guard that enforces
///     the build-first and generation rules. S4 (#4352b) supplies the
///     Android implementation; `NoopRecordingProtectionOwner` is the honest
///     default everywhere else: [RecordingProtectionVerdict.foregroundOnly].
///   * [RecordingProtectionBuild] — the artifact's *compiled* capability, and
///     the `channel` label stamped into the diagnostics export.
///
/// ## The audit script is the other half
///
/// [RecordingProtectionBuild.supports] claims which service types an artifact
/// can host. That claim is only worth anything if the shipped manifest agrees,
/// so `scripts/audit_fgs_declarations.sh` asserts, per artifact, the exact set
/// of `FOREGROUND_SERVICE*` permissions and foreground-service declarations —
/// zero for a default Play build, exactly three permissions plus the
/// `connectedDevice` service for an `FGS_FORM_APPROVED=true` Play build. CI
/// runs it on both checked-in overlays, so a capability claim here and a
/// manifest cannot drift apart unnoticed.
library;

import '../../../core/location/recording_location_settings.dart';
import '../../../core/platform/app_flavor.dart';

/// What a recording session is acquiring, and therefore which
/// foreground-service type may legitimately protect it.
///
/// Android 14+ requires a type-specific permission per
/// `foregroundServiceType`, and Play's Foreground Service Use declaration is
/// per type. A GPS-off OBD2 trip must therefore **not** be protected by a
/// `location`-typed service: that would collect location purely to stay
/// alive, which #4352 §4 forbids.
enum RecordingSourceMode {
  /// GPS only — geolocator's own `location`-typed service is the natural
  /// (and already-shipping) owner.
  locationOnly,

  /// OBD2 only, GPS path off or unavailable — needs a `connectedDevice`-typed
  /// service of our own (S4). This is failure mode M3: today nothing at all
  /// protects it.
  connectedDeviceOnly,

  /// GPS **and** a connected adapter. One service, never two: a
  /// `location`-typed service already raises the whole process's importance,
  /// which covers the OBD2 threads.
  both;

  /// Whether this mode acquires location at all.
  bool get needsLocation => this != RecordingSourceMode.connectedDeviceOnly;

  /// Whether this mode holds a connected-device link (BLE or Classic).
  bool get needsConnectedDevice => this != RecordingSourceMode.locationOnly;
}

/// The six terminal answers to "is this session protected?".
///
/// Ordered from least to most capable so a composer can take the *worst* of
/// several observations without a lookup table.
enum RecordingProtectionVerdict {
  /// Not yet determined — a lease was never requested, or the platform
  /// answer has not arrived. **Never treat this as protected**: the whole
  /// point of the contract is that silence is not acceptance.
  unknown,

  /// This artifact cannot host the required foreground service at all: the
  /// `FGS_FORM_APPROVED` define is absent, or the manifest overlay does not
  /// declare the type this [RecordingSourceMode] needs. No permission grant
  /// and no OS state can change it — only a different build.
  unsupportedBuild,

  /// The build could host the service, but a runtime prerequisite is missing
  /// (location permission, notification permission, …).
  permissionMissing,

  /// Everything was in place and the OS still refused the promotion —
  /// a background-start restriction, or `startForeground` throwing.
  refusedByOs,

  /// Recording continues, but **only while the app is in the foreground**.
  /// The honest default: data is still acquired and stays recoverable, and
  /// nothing may advertise screen-off reliability.
  foregroundOnly,

  /// The OS accepted the promotion for this session generation. The only
  /// verdict that may claim background recording.
  acknowledged;

  /// True only for [acknowledged]. The single predicate the rest of the app
  /// is allowed to branch on when deciding whether to *promise* anything.
  bool get isProtected => this == RecordingProtectionVerdict.acknowledged;

  /// The worse (less capable) of two verdicts — enum order is the ranking.
  static RecordingProtectionVerdict worst(
    RecordingProtectionVerdict a,
    RecordingProtectionVerdict b,
  ) =>
      a.index <= b.index ? a : b;
}

/// Why a [RecordingProtectionVerdict] came out the way it did.
///
/// Typed rather than free text so S5 can map each case to an ARB key without
/// a shipped English string ever leaking through this layer.
enum RecordingProtectionReason {
  /// No lease was ever asked for.
  notRequested,

  /// `FGS_FORM_APPROVED` was not compiled into this artifact.
  foregroundServiceNotCompiled,

  /// Compiled in, but this artifact's manifest overlay declares no service of
  /// the required type (today: `connectedDevice` on the F-Droid overlay).
  serviceTypeNotDeclared,

  /// The platform has no foreground-service concept (iOS, desktop). Not a
  /// defect — iOS protection is #4357's separate contract.
  platformHasNoForegroundService,

  /// A runtime location permission the requested type requires is missing.
  locationPermissionMissing,

  /// Notification display permission is missing. Distinct from FGS
  /// eligibility on purpose: #4352 §5 forbids conflating them.
  notificationPermissionMissing,

  /// The OS refused a service start from the background.
  backgroundStartNotAllowed,

  /// The native start call threw. The guard converts it to a verdict.
  nativeStartThrew,

  /// The service was started but never acknowledged its promotion in time.
  acknowledgementTimedOut,

  /// An acknowledgement arrived for a generation that is no longer current —
  /// a late native reply after Stop, or after a new session began.
  generationSuperseded,

  /// The OS accepted the promotion.
  promoted,

  /// Deliberate foreground-only operation (the no-op owner's answer, and the
  /// disclosed fallback after a refusal).
  policyForegroundOnly,
}

/// What *this artifact* can do, before any device or permission is consulted.
///
/// Compile-time constants only, so it folds away under tree-shaking and tests
/// can reason about both channels without a platform channel.
class RecordingProtectionBuild {
  /// Describe an artifact explicitly (tests, and the export's fixtures).
  const RecordingProtectionBuild({
    required this.foregroundServiceCompiled,
    required this.libre,
  });

  /// The running artifact.
  static const RecordingProtectionBuild current = RecordingProtectionBuild(
    foregroundServiceCompiled: kGpsRecordingForegroundServiceEnabled,
    libre: AppFlavor.isLibre,
  );

  /// Whether `--dart-define=FGS_FORM_APPROVED=true` was passed. Drives BOTH
  /// the Dart `ForegroundNotificationConfig` and the manifest-overlay swap
  /// (#3173), so it is the single honest answer to "can this build promote?".
  final bool foregroundServiceCompiled;

  /// The GMS-free F-Droid build ([AppFlavor.isLibre]).
  final bool libre;

  /// Machine-readable channel label for the diagnostics export. Never shown
  /// to a user — S5 owns every user-visible word.
  String get channel => libre ? 'fdroid' : 'play';

  /// Whether this artifact declares a foreground service able to protect
  /// [mode].
  ///
  /// `connectedDevice` ships only in the **play** FGS-approved overlay
  /// (`android/app/src/play/AndroidManifestFgsApproved.xml`); the F-Droid
  /// overlay is location-only today. `scripts/audit_fgs_declarations.sh`
  /// asserts exactly that, per artifact, in CI — so this method cannot
  /// quietly out-claim the manifest.
  bool supports(RecordingSourceMode mode) {
    if (!foregroundServiceCompiled) return false;
    if (!mode.needsConnectedDevice) return true;
    return !libre;
  }

  /// The verdict the build alone already decides, or `null` when the build
  /// is capable and the answer must come from the platform.
  RecordingProtectionVerdict? verdictFor(RecordingSourceMode mode) {
    if (supports(mode)) return null;
    return RecordingProtectionVerdict.unsupportedBuild;
  }

  /// The reason behind [verdictFor]'s refusal.
  RecordingProtectionReason reasonFor(RecordingSourceMode mode) =>
      foregroundServiceCompiled
          ? RecordingProtectionReason.serviceTypeNotDeclared
          : RecordingProtectionReason.foregroundServiceNotCompiled;

  /// Export shape. Purely build facts — no device state, no identifiers.
  Map<String, Object?> toJson() => <String, Object?>{
        'channel': channel,
        'foregroundServiceCompiled': foregroundServiceCompiled,
      };
}

/// One session's protection answer: the [verdict], its [reason], and the
/// `sessionGeneration` it was issued for.
class RecordingProtectionStatus {
  /// Build a status directly. Prefer the named constructors below.
  const RecordingProtectionStatus({
    required this.verdict,
    required this.reason,
    required this.sourceMode,
    required this.sessionGeneration,
    this.detail,
  });

  /// Nothing is known yet. The starting value of every session.
  const RecordingProtectionStatus.unknown({
    required RecordingSourceMode sourceMode,
    int sessionGeneration = 0,
    RecordingProtectionReason reason = RecordingProtectionReason.notRequested,
    String? detail,
  }) : this(
          verdict: RecordingProtectionVerdict.unknown,
          reason: reason,
          sourceMode: sourceMode,
          sessionGeneration: sessionGeneration,
          detail: detail,
        );

  /// This artifact can never protect [sourceMode].
  const RecordingProtectionStatus.unsupportedBuild({
    required RecordingSourceMode sourceMode,
    required RecordingProtectionReason reason,
    int sessionGeneration = 0,
    String? detail,
  }) : this(
          verdict: RecordingProtectionVerdict.unsupportedBuild,
          reason: reason,
          sourceMode: sourceMode,
          sessionGeneration: sessionGeneration,
          detail: detail,
        );

  /// Recording continues, foreground-only, and says so.
  const RecordingProtectionStatus.foregroundOnly({
    required RecordingSourceMode sourceMode,
    int sessionGeneration = 0,
    RecordingProtectionReason reason =
        RecordingProtectionReason.policyForegroundOnly,
    String? detail,
  }) : this(
          verdict: RecordingProtectionVerdict.foregroundOnly,
          reason: reason,
          sourceMode: sourceMode,
          sessionGeneration: sessionGeneration,
          detail: detail,
        );

  /// The OS accepted the promotion for [sessionGeneration].
  const RecordingProtectionStatus.acknowledged({
    required RecordingSourceMode sourceMode,
    required int sessionGeneration,
    String? detail,
  }) : this(
          verdict: RecordingProtectionVerdict.acknowledged,
          reason: RecordingProtectionReason.promoted,
          sourceMode: sourceMode,
          sessionGeneration: sessionGeneration,
          detail: detail,
        );

  final RecordingProtectionVerdict verdict;
  final RecordingProtectionReason reason;
  final RecordingSourceMode sourceMode;

  /// The session generation this answer belongs to. A status whose generation
  /// is not the live one is evidence about a session that has already ended.
  final int sessionGeneration;

  /// Diagnostic free text (an exception's message, a native reason code).
  /// Never rendered; the export carries it, the UI reads [reason].
  final String? detail;

  /// Only an acknowledged promotion may claim background recording.
  bool get isProtected => verdict.isProtected;

  /// Whether this answer still describes [generation].
  bool matchesGeneration(int generation) => sessionGeneration == generation;

  /// The same answer restated for a superseded generation: whatever the
  /// platform said, it is no longer about the live session.
  RecordingProtectionStatus superseded() => RecordingProtectionStatus(
        verdict: RecordingProtectionVerdict.unknown,
        reason: RecordingProtectionReason.generationSuperseded,
        sourceMode: sourceMode,
        sessionGeneration: sessionGeneration,
        detail: detail,
      );

  /// Export shape, beside the recording-session journal.
  Map<String, Object?> toJson() => <String, Object?>{
        'verdict': verdict.name,
        'reason': reason.name,
        'sourceMode': sourceMode.name,
        'sessionGeneration': sessionGeneration,
        if (detail != null) 'detail': detail,
      };

  @override
  bool operator ==(Object other) =>
      other is RecordingProtectionStatus &&
      other.verdict == verdict &&
      other.reason == reason &&
      other.sourceMode == sourceMode &&
      other.sessionGeneration == sessionGeneration &&
      other.detail == detail;

  @override
  int get hashCode =>
      Object.hash(verdict, reason, sourceMode, sessionGeneration, detail);

  @override
  String toString() => 'RecordingProtectionStatus(${toJson()})';
}
