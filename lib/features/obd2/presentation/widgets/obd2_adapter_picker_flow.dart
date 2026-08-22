// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_adapter_picker.dart';

/// #3760 — the picker sheet's scan → pick → connect state machine
/// (fields, pre-flight + radio scan, connect + pinned-MAC persist),
/// split out of `obd2_adapter_picker.dart` as a `part` mixin
/// (move-only, behaviour preserved). Constrained
/// `on ConsumerState<Obd2AdapterPickerSheet>` so it keeps `ref` /
/// `widget` / `setState`; the State applies it first so
/// [_Obd2AdapterPickerBody] can read the same private fields.
mixin _Obd2AdapterPickerFlow on ConsumerState<Obd2AdapterPickerSheet> {
  _Phase _phase = _Phase.scanning;
  StreamSubscription<List<ResolvedObd2Candidate>>? _sub;
  List<ResolvedObd2Candidate> _candidates = const [];
  Obd2ConnectionError? _error;

  /// #3103 — false on iOS (no Classic facade wired): the picker then explains
  /// that iPhone can only use Bluetooth-LE adapters, instead of silently
  /// showing nothing when the user has a Classic-only adapter.
  bool _supportsClassicDiscovery = true;

  void _startScan() {
    setState(() {
      _phase = _Phase.scanning;
      _candidates = const [];
      _error = null;
    });
    unawaited(_preflightThenScan());
  }

  /// Resolve the scan-readiness probe BEFORE burning a radio-scan
  /// window: a user with Bluetooth off (or Android location services
  /// off — the blocker that makes a scan return empty with no error)
  /// gets the diagnostic instantly instead of after a spinner that was
  /// always going to time out.
  ///
  /// FAIL-OPEN by design: only a positively-identified, non-promptable
  /// blocker diverts. `ready` scans, obviously — but so does a plain
  /// `permissionDenied`, because `scan()` calls `permissions.request()`
  /// and the scan IS the prompt; pre-flight-blocking it would mean the
  /// OS permission dialog could never appear. The probe itself never
  /// throws (probe faults resolve optimistically), so a broken probe
  /// can never hide the scan path either.
  Future<void> _preflightThenScan() async {
    final readiness =
        await ref.read(obd2ScanReadinessProbeProvider).resolve();
    if (!mounted || _phase != _Phase.scanning) return;
    if (!readiness.canScan && !readiness.isPromptable) {
      setState(() => _phase = _Phase.blocked);
      return;
    }
    _beginRadioScan();
  }

  void _beginRadioScan() {
    final connection = ref.read(obd2ConnectionProvider);
    _supportsClassicDiscovery = connection.supportsClassicDiscovery;
    unawaited(_sub?.cancel());
    _sub = connection.scan().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _candidates = list;
          if (list.isNotEmpty) _phase = _Phase.selecting;
        });
      },
      onError: (Object e, _) {
        if (!mounted || e is! Obd2ConnectionError) return;
        setState(() {
          _error = e;
          _phase = _Phase.error;
        });
      },
    );
  }

  Future<void> _connect(ResolvedObd2Candidate candidate) async {
    // #779 — pair-only flow: pop the candidate instead of opening a
    // connection. The caller persists it and closes.
    if (widget.pairOnly) {
      Navigator.of(context).pop(candidate);
      return;
    }
    setState(() => _phase = _Phase.connecting);
    // errorlog_30 — capture the post-connect persist's provider reads BEFORE
    // the first `await`. `connect()` is async and the sheet can be dismissed/
    // unmounted while it runs; reading `ref` AFTER unmount throws `Bad state:
    // Using "ref" when a widget is about to or has been unmounted is unsafe`.
    // Both providers are `keepAlive: true`, so the captures stay valid and the
    // best-effort persist still completes on the unmounted path (the connect
    // succeeded — the pinned MAC must be written either way).
    final activeProfile = ref.read(activeVehicleProfileProvider);
    final vehicleListNotifier = ref.read(vehicleProfileListProvider.notifier);
    final connection = ref.read(obd2ConnectionProvider);
    // #3184(f) — end the scan stream before the connect begins. NOT
    // awaited: a cancel future can take extra event-loop turns (and never
    // completes under widget-test fake-async) and must delay neither the
    // spinner nor the connect. Trace separation does not depend on this
    // ordering — `Obd2ConnectTraceLog.beginTrace` SUPERSEDES a live
    // picker-scan trace, so the connect always opens its own root. The
    // connect path stops the radio itself (stopScanBeforeConnect); this
    // cancels the Dart side.
    unawaited(_sub?.cancel());
    _sub = null;
    try {
      // #3527 — supervised one-shot dial (same contract as the pinned
      // path above); the container is read pre-await (errorlog_30).
      final service = await obd2PickerSupervisedDial(
          ProviderScope.containerOf(context, listen: false),
          () => connection.connect(candidate));
      if (service == null) {
        // Dial miss — surface the same typed error the classic path threw.
        throw const Obd2AdapterUnresponsive();
      }
      // #1188 — persist MAC + display name back onto the active vehicle
      // profile so the next session takes the pinned-MAC fast path and skips
      // the picker. Best-effort; uses the pre-await captures (errorlog_30) so
      // it never touches `ref` after unmount.
      await _persistPickedAdapterToActiveVehicle(
        candidate,
        activeProfile,
        vehicleListNotifier,
      );
      if (!mounted) return;
      if (widget.returnPickedConnection) {
        // #1310 — onboarding flow needs the MAC alongside the service
        // so it can persist `obd2AdapterMac` on the freshly-saved
        // profile (no `active` vehicle exists yet during onboarding,
        // so [_persistPickedAdapterToActiveVehicle] no-ops).
        final mac = candidate.candidate.deviceId;
        final name = candidate.candidate.deviceName.isEmpty
            ? candidate.profile.displayName
            : candidate.candidate.deviceName;
        Navigator.of(context).pop(
          PickedObd2Connection(service: service, mac: mac, name: name),
        );
      } else {
        Navigator.of(context).pop(service);
      }
    } on Obd2ConnectionError catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': '_Obd2AdapterPicker._connect: adapter connect failed'
      }));
      if (!mounted) return;
      setState(() {
        _error = e;
        _phase = _Phase.error;
      });
    }
  }

  /// Write the user's picked adapter MAC + display name onto the
  /// active vehicle profile when missing or different (#1188). Runs
  /// only when an active profile exists; no-op otherwise. Errors are
  /// swallowed (debug-printed) — the connect path the user is
  /// completing is the priority.
  ///
  /// Persists [VehicleProfile.obd2AdapterMac] (#1310) so the auto-record
  /// orchestrator's gate (`obd2AdapterMac != null &&
  /// backgroundLocationConsent`) flips to ready as soon as the user
  /// successfully pairs — without this, the auto-record toggle silently
  /// dropped users who picked an adapter outside the OBD2 onboarding
  /// wizard.
  ///
  /// [active] and [listNotifier] are captured by the caller BEFORE its first
  /// `await` (errorlog_30): this runs post-connect, when the sheet may already
  /// be unmounted, so reading them off `ref` here would throw the "ref used
  /// after unmount" [StateError]. Both source providers are `keepAlive: true`.
  Future<void> _persistPickedAdapterToActiveVehicle(
    ResolvedObd2Candidate candidate,
    VehicleProfile? active,
    VehicleProfileList listNotifier,
  ) async {
    try {
      if (active == null) return;
      // #2282 concern 3 / #3168 — identity capture lives at the data-layer
      // [Obd2AdapterIdentity] seam: it stores the iOS CBPeripheral UUID
      // reconnection key when the deviceId is UUID-shaped (and null for an
      // Android MAC), so this widget no longer branches on the platform
      // (#2350 ratchet).
      final identity = Obd2AdapterIdentity.fromCandidate(candidate);
      if (active.obd2AdapterMac == identity.deviceId &&
          active.obd2AdapterName == identity.name &&
          active.pairedAdapterUuidIos == identity.uuidIos) {
        return; // already persisted — skip the redundant write.
      }
      final updated = active.copyWith(
        obd2AdapterMac: identity.deviceId,
        obd2AdapterName: identity.name,
        pairedAdapterUuidIos: identity.uuidIos,
      );
      await listNotifier.save(updated);
    } catch (e, st) {
      // #2308 — this write is the ONLY path that pre-populates the
      // pinned-MAC fast-connect; a HiveError here silently drops the
      // adapter MAC and breaks auto-connect on every later session, so
      // it must leave a release-visible breadcrumb (not just debugPrint).
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': '_persistPickedAdapterToActiveVehicle',
      }));
    }
  }
}
