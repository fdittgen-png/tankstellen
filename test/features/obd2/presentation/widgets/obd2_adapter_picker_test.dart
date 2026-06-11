// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_adapter_picker.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import '../../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();
  group('Obd2AdapterPickerSheet (#743)', () {
    testWidgets('shows the scanning state on open', (tester) async {
      final svc = _buildService(const [[]]);
      await _pump(tester, svc);
      expect(find.byKey(const Key('obdPickerScanning')), findsOneWidget);
    });

    testWidgets('renders the ranked candidates once scan emits',
        (tester) async {
      final svc = _buildService([
        [
          _scanHit(name: 'vLinker FD', rssi: -55),
          _scanHit(name: 'OBDLink MX+', rssi: -40),
        ],
      ]);
      await _pump(tester, svc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('obdPickerSelecting')), findsOneWidget);
      // OBDLink is stronger → ranks first by RSSI.
      expect(find.text('OBDLink MX+'), findsOneWidget);
      expect(find.text('vLinker FD'), findsOneWidget);
    });

    testWidgets(
        '#3103 — recognized + NAMED-unrecognized render in two sections, with '
        'the BLE-only notice when Classic discovery is unavailable',
        (tester) async {
      final svc = _buildService([
        [
          _scanHit(name: 'vLinker FD', rssi: -50), // recognized BLE profile
          _scanHit(name: 'My Random Dongle', rssi: -70), // named, unknown
        ],
      ]);
      await _pump(tester, svc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The recognized adapter shows as before.
      expect(find.text('vLinker FD'), findsOneWidget);
      // The unrecognized device is SURFACED (not dropped) under the "other
      // devices" header with a tap-to-try subtitle.
      expect(find.text('My Random Dongle'), findsOneWidget);
      expect(find.text('Other Bluetooth devices'), findsOneWidget);
      expect(find.textContaining('Unrecognized — tap to try'), findsOneWidget);
      // _buildService wires no Classic facade ⇒ supportsClassicDiscovery is
      // false ⇒ the iOS-style "BLE adapters only" notice is shown.
      expect(
        find.byKey(const Key('obdPickerBleOnlyNotice')),
        findsOneWidget,
      );
    });

    testWidgets('tapping a candidate transitions to connecting state',
        (tester) async {
      final svc = _buildService([
        [_scanHit(name: 'vLinker FD', rssi: -55)],
      ]);
      await _pump(tester, svc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('vLinker FD'));
      await tester.pump(); // state flip only — don't settle, the silent
      // channel intentionally leaves a pending read timeout that
      // eventually surfaces as Obd2AdapterUnresponsive; we're only
      // asserting the optimistic "connecting" state got rendered.
      expect(find.byKey(const Key('obdPickerConnecting')), findsOneWidget);
      // Drain the init read timeouts so the test harness exits cleanly.
      // #2233 moved the ELM327 init out of the transport into
      // Obd2Service.connect, which wraps each command in a one-shot
      // connect-retry (_withConnectRetry): the first ATZ times out
      // (5 s), waits connectRetryDelay (150 ms), then retries and times
      // out again (5 s). Pump past both timers + the retry delay so no
      // timer is pending when the widget tree is disposed.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
    });

    testWidgets(
        'shows the retry button + error message + open-settings CTA on permission denied',
        (tester) async {
      final svc = Obd2ConnectionService(
        registry: Obd2AdapterRegistry.defaults(),
        permissions: _FakePermissions(Obd2PermissionState.denied),
        bluetooth: _StreamingFacade(const []),
      );
      await _pump(tester, svc);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('obdPickerError')), findsOneWidget);
      // The denial error message itself is rendered.
      expect(
        find.text('Bluetooth permission denied'),
        findsOneWidget,
      );
      // Retry stays visible — the user might be on a transient denial
      // (first prompt, "Don't Allow") and Retry will re-prompt.
      expect(find.byKey(const Key('obdPickerRetry')), findsOneWidget);
      // New CTA introduced for the iOS permanently-denied case: deep-
      // link into the app's Settings row so the user can flip the
      // Bluetooth toggle. Tappable by key — we don't verify the platform
      // channel call here (it's a no-op in widget tests by default).
      expect(
        find.byKey(const Key('obdPickerOpenSettings')),
        findsOneWidget,
      );
    });
  });

  // #1188 — pinned-MAC fast path. `showObd2AdapterPicker` accepts a
  // [pinnedMac] for the active vehicle's adapter. When set, it tries
  // a silent direct connect via [Obd2ConnectionService.connectByMac]
  // and only falls back to the modal sheet when that fails.
  group('showObd2AdapterPicker pinned-MAC fast path (#1188)', () {
    testWidgets('pinnedMac=null shows the sheet (regression check)',
        (tester) async {
      final svc = _RecordingFakeConnection.success();
      final completer = Completer<Obd2Service?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    completer.complete(showObd2AdapterPicker(ctx));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      // Sheet rendered → its title is on screen.
      expect(find.text('Pick an OBD2 adapter'), findsOneWidget);
      expect(svc.connectByMacCalls, isEmpty);
      // Tear down the open future cleanly.
      Navigator.of(tester.element(find.text('Pick an OBD2 adapter')))
          .pop();
      await tester.pumpAndSettle();
      await completer.future;
    });

    testWidgets(
        'pinnedMac with successful connect resolves silently (no sheet)',
        (tester) async {
      final fakeService = _NoopObd2Service();
      final svc = _RecordingFakeConnection(
        connectByMacResult: fakeService,
      );
      final completer = Completer<Obd2Service?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    completer.complete(showObd2AdapterPicker(
                      ctx,
                      pinnedMac: 'AA:BB:CC:DD:EE:FF',
                      pinnedAdapterName: 'vLinker FS',
                    ));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(svc.connectByMacCalls, ['AA:BB:CC:DD:EE:FF']);
      // No sheet rendered.
      expect(find.text('Pick an OBD2 adapter'), findsNothing);
      // Future resolved with the service.
      final resolved = await completer.future;
      expect(resolved, same(fakeService));
    });

    testWidgets(
        'pinnedMac with failed connect (returns null) opens sheet + snackbar',
        (tester) async {
      final svc = _RecordingFakeConnection(
        connectByMacResult: null, // simulate timeout / out-of-range
      );
      final completer = Completer<Obd2Service?>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    completer.complete(showObd2AdapterPicker(
                      ctx,
                      pinnedMac: 'AA:BB:CC:DD:EE:FF',
                      pinnedAdapterName: 'vLinker FS',
                    ));
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(svc.connectByMacCalls, ['AA:BB:CC:DD:EE:FF']);
      // Sheet IS rendered now (fallback) — its title shows.
      expect(find.text('Pick an OBD2 adapter'), findsOneWidget);
      // Snackbar with the pinned name carries the localized message.
      expect(
        find.textContaining("Couldn't reach 'vLinker FS'"),
        findsOneWidget,
      );

      // Drain the picker — the underlying scan stream is empty so it
      // sits in `scanning`. Pop the sheet to resolve the future.
      Navigator.of(tester.element(find.text('Pick an OBD2 adapter')))
          .pop();
      await tester.pumpAndSettle();
      await completer.future;
    });
  });

  // #2745 — error-log #14 trace #5: an `[ui] Obd2AdapterUnresponsive` ERROR
  // was spooled for the pinned-connect failure even though the same condition
  // is already surfaced to the user (the fall-through sheet + snackbar). The
  // EXPECTED, user-actionable connect conditions must be a breadcrumb, NOT an
  // ERROR trace; a GENUINE fault (permission denied) must still ERROR-log.
  group('pinned-connect telemetry de-noise (#2745)', () {
    late _CaptureRecorder rec;

    setUp(() {
      rec = _CaptureRecorder();
      errorLogger.testRecorderOverride = rec;
      BreadcrumbCollector.clear();
    });

    Future<void> pumpAndOpen(WidgetTester tester, Object thrown) async {
      final svc = _RecordingFakeConnection(connectByMacError: thrown);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [obd2ConnectionProvider.overrideWith((_) => svc)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showObd2AdapterPicker(ctx,
                      pinnedMac: 'AA:BB:CC:DD:EE:FF',
                      pinnedAdapterName: 'vLinker FS'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets(
        'an expected Obd2AdapterUnresponsive is a breadcrumb, NOT an ERROR',
        (tester) async {
      await pumpAndOpen(tester, const Obd2AdapterUnresponsive());

      expect(rec.errors, isEmpty,
          reason: 'an already-user-surfaced condition must NOT ERROR-log');
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 connect failed — expected user condition'),
      );

      Navigator.of(tester.element(find.text('Pick an OBD2 adapter'))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('a genuine Obd2PermissionDenied STILL ERROR-logs (the guard)',
        (tester) async {
      await pumpAndOpen(tester, const Obd2PermissionDenied());

      expect(rec.errors, hasLength(1),
          reason: 'permission denial is a genuine, diagnostic-worthy fault');
      expect(rec.errors.single.toString(), contains('pinned connect failed'));

      Navigator.of(tester.element(find.text('Pick an OBD2 adapter'))).pop();
      await tester.pumpAndSettle();
    });
  });

  // errorlog_30 — a real Open-Testing trace: `_connect` runs `connect()`
  // async, then `_persistPickedAdapterToActiveVehicle` touched `ref` AFTER
  // the await. When the sheet was dismissed/unmounted while `connect()` was
  // still resolving, that post-await `ref` read threw
  //   `Bad state: Using "ref" when a widget is about to or has been
  //    unmounted is unsafe.`
  // The fix captures the active profile + list notifier BEFORE the first
  // await, so the persist never touches `ref` post-unmount AND still
  // completes (the connect succeeded — the pinned MAC must be written).
  group('post-connect persist is unmount-safe (errorlog_30)', () {
    late _CaptureRecorder rec;

    setUp(() {
      rec = _CaptureRecorder();
      errorLogger.testRecorderOverride = rec;
    });

    testWidgets(
        'unmounting the sheet before connect resolves does NOT ref-after-unmount',
        (tester) async {
      final list = _RecordingVehicleList([
        const VehicleProfile(id: 'v1', name: 'Golf'),
      ]);
      // connect() is gated on a completer the test controls, so we can
      // unmount the sheet while it is still pending.
      final svc = _GatedConnection();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            obd2ConnectionProvider.overrideWith((_) => svc),
            vehicleProfileListProvider.overrideWith(() => list),
            activeVehicleProfileProvider.overrideWith(
              () => _StubActiveVehicle(
                const VehicleProfile(id: 'v1', name: 'Golf'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Obd2AdapterPickerSheet()),
          ),
        ),
      );
      // Scan emits one candidate → selecting state with a tappable tile.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('vLinker FD'));
      await tester.pump(); // flips to connecting; connect() now pending.

      // Dismiss the sheet WHILE connect() is still in flight — this is the
      // crash window: the sheet unmounts, then connect() resolves and the
      // post-await persist runs.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      expect(
        find.byType(Obd2AdapterPickerSheet),
        findsNothing,
        reason: 'sheet must be unmounted before connect resolves',
      );

      // Now resolve the connect — on master this drove a ref read after
      // unmount, swallowed into a `[ui] Bad state` ERROR trace.
      svc.completeConnect(_NoopObd2Service());
      await tester.pump();
      await tester.pump();

      // No ref-after-unmount StateError reached the error logger.
      final unmountErrors = rec.errors
          .map((e) => e.toString())
          .where((s) => s.contains('unmounted') || s.contains('Bad state'))
          .toList();
      expect(
        unmountErrors,
        isEmpty,
        reason: 'post-await persist must not touch `ref` after unmount',
      );
      // The persist still happened via the pre-await capture — the picked
      // adapter MAC was written even though the sheet was gone.
      expect(list.savedProfiles, hasLength(1));
      expect(list.savedProfiles.single.obd2AdapterMac, 'id-vLinker FD');
    });

    testWidgets('the mounted path still persists the picked adapter',
        (tester) async {
      final list = _RecordingVehicleList([
        const VehicleProfile(id: 'v1', name: 'Golf'),
      ]);
      final svc = _GatedConnection();
      final fakeService = _NoopObd2Service();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            obd2ConnectionProvider.overrideWith((_) => svc),
            vehicleProfileListProvider.overrideWith(() => list),
            activeVehicleProfileProvider.overrideWith(
              () => _StubActiveVehicle(
                const VehicleProfile(id: 'v1', name: 'Golf'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Obd2AdapterPickerSheet()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('vLinker FD'));
      await tester.pump();

      // Resolve the connect while the sheet is STILL mounted (the normal
      // happy path) → the persist must run and pop with the service.
      svc.completeConnect(fakeService);
      await tester.pumpAndSettle();

      expect(rec.errors, isEmpty);
      expect(list.savedProfiles, hasLength(1));
      expect(list.savedProfiles.single.obd2AdapterMac, 'id-vLinker FD');
      expect(list.savedProfiles.single.obd2AdapterName, 'vLinker FD');
    });
  });
}

/// [VehicleProfileList] fake that seeds an initial list and records every
/// [save] so the errorlog_30 tests can assert the picked adapter MAC was
/// persisted. Mirrors `auto_record_section_test.dart`'s pattern.
class _RecordingVehicleList extends VehicleProfileList {
  _RecordingVehicleList(this._seed);
  final List<VehicleProfile> _seed;
  final List<VehicleProfile> savedProfiles = <VehicleProfile>[];

  @override
  List<VehicleProfile> build() => List<VehicleProfile>.from(_seed);

  @override
  Future<void> save(VehicleProfile profile) async {
    savedProfiles.add(profile);
    state = [..._seed.where((v) => v.id != profile.id), profile];
  }
}

/// Stub [ActiveVehicleProfile] returning a fixed value with no storage I/O.
class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;
  @override
  VehicleProfile? build() => _value;
}

/// Connection fake whose `connect()` is gated on a completer the test
/// controls — so a test can unmount the sheet mid-connect and only then
/// resolve, reproducing the errorlog_30 crash window. `scan()` emits a
/// single candidate so the picker reaches `selecting` with a tappable tile.
class _GatedConnection extends Obd2ConnectionService {
  _GatedConnection()
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _FakePermissions(Obd2PermissionState.granted),
          bluetooth: _StreamingFacade(const []),
        );

  final Completer<Obd2Service> _connectGate = Completer<Obd2Service>();

  void completeConnect(Obd2Service service) => _connectGate.complete(service);

  @override
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    yield [
      ResolvedObd2Candidate(
        candidate: _scanHit(name: 'vLinker FD', rssi: -50),
        profile: const Obd2AdapterProfile(
          id: 'vlinker-ble',
          displayName: 'vLinker FD / MC (BLE)',
        ),
      ),
    ];
  }

  @override
  Future<Obd2Service> connect(ResolvedObd2Candidate candidate) =>
      _connectGate.future;
}

/// Captures every `errorLogger.log` -> `record` call so the de-noise tests
/// can assert an expected condition was NOT ERROR-logged.
class _CaptureRecorder implements TraceRecorder {
  final errors = <Object>[];
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    errors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Recording fake for [Obd2ConnectionService] that lets the pinned-MAC
/// tests drive `connectByMac` without spinning up a real BLE stack.
/// Sheet-fallback paths still need a working `scan` because the
/// underlying [Obd2AdapterPickerSheet] subscribes to it on init —
/// returning an empty stream sits the sheet in its scanning state
/// indefinitely, which is exactly what the tests need to assert
/// "the sheet IS rendered" without chasing further state transitions.
class _RecordingFakeConnection extends Obd2ConnectionService {
  _RecordingFakeConnection({this.connectByMacResult, this.connectByMacError})
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _FakePermissions(Obd2PermissionState.granted),
          bluetooth: _StreamingFacade(const []),
        );
  factory _RecordingFakeConnection.success() =>
      _RecordingFakeConnection(connectByMacResult: _NoopObd2Service());

  final Obd2Service? connectByMacResult;
  final Object? connectByMacError;
  final List<String> connectByMacCalls = [];

  @override
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
    String? adapterName,
  }) async {
    connectByMacCalls.add(mac);
    if (connectByMacError != null) throw connectByMacError!;
    return connectByMacResult;
  }

  @override
  Stream<List<ResolvedObd2Candidate>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    // Empty stream — the picker sheet sits in its scanning state.
  }
}

/// Minimal [Obd2Service] stand-in. The pinned-MAC tests only need
/// identity comparison (`same(fakeService)`); no transport calls fire.
class _NoopObd2Service implements Obd2Service {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- helpers ---------------------------------------------------------

Future<void> _pump(
  WidgetTester tester,
  Obd2ConnectionService svc,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        obd2ConnectionProvider.overrideWith((_) => svc),
        // errorlog_30 — `_connect` now reads the vehicle providers eagerly
        // (pre-await capture) so the post-connect persist never touches
        // `ref` after unmount. Stub them so these Hive-free widget tests
        // don't fault the real repository's `Hive.openBox` path.
        vehicleProfileListProvider.overrideWith(
          () => _RecordingVehicleList(const []),
        ),
        activeVehicleProfileProvider.overrideWith(
          () => _StubActiveVehicle(null),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Obd2AdapterPickerSheet()),
      ),
    ),
  );
}

Obd2ConnectionService _buildService(
    List<List<Obd2AdapterCandidate>> batches) {
  return Obd2ConnectionService(
    registry: Obd2AdapterRegistry.defaults(),
    permissions: _FakePermissions(Obd2PermissionState.granted),
    bluetooth: _StreamingFacade(batches),
  );
}

Obd2AdapterCandidate _scanHit({required String name, int rssi = -60}) =>
    Obd2AdapterCandidate(
      deviceId: 'id-$name',
      deviceName: name,
      advertisedServiceUuids: const [],
      rssi: rssi,
    );

class _FakePermissions implements Obd2Permissions {
  final Obd2PermissionState state;
  _FakePermissions(this.state);
  @override
  Future<Obd2PermissionState> current() async => state;
  @override
  Future<Obd2PermissionState> request() async => state;
  @override
  Future<bool> requestNotifications() async => true;
}

class _StreamingFacade implements BluetoothFacade {
  final List<List<Obd2AdapterCandidate>> batches;
  _StreamingFacade(this.batches);

  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    for (final batch in batches) {
      yield batch;
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  ElmByteChannel channelFor(
    String deviceId,
    Obd2AdapterProfile profile,
  ) =>
      _SilentChannel();

  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      _SilentChannel();
}

/// Silent channel — never answers, so the transport's init sequence
/// eventually times out. Used only by the "connecting" test; it's
/// there to prove the transition fires, not to complete the connect.
class _SilentChannel implements ElmByteChannel {
  final StreamController<List<int>> _ctrl = StreamController.broadcast();
  bool _open = false;
  @override
  bool get isOpen => _open;
  @override
  Stream<List<int>> get incoming => _ctrl.stream;
  @override
  Future<void> open() async {
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {}
  @override
  Future<void> close() async {
    _open = false;
    await _ctrl.close();
  }
}
