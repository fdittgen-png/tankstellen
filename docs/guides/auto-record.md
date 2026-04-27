# Hands-free trip auto-record (Android)

Status: phase 2b-2 — native bridge shipped, `AutoTripCoordinator` wired
to the active vehicle list via `AutoRecordOrchestrator`.

This document explains the Android-side foreground service that drives
hands-free trip auto-record (issue #1004) and how to verify a build.

## Why a foreground service?

Modern Android (Doze + App Standby + Android 12+ background-launch
restrictions) will kill ordinary background services and suspend BLE
callbacks while the app is not visible. The user's car drives by in
the morning, the phone is in the kitchen, the app process is dead — a
non-foreground service simply will not run.

A foreground service with `foregroundServiceType="connectedDevice"`
and a persistent low-importance notification is the OS-supported way
to keep a BLE listener alive long enough to observe the user's paired
adapter coming into range.

## Permissions

Declared in `android/app/src/main/AndroidManifest.xml`:

| Permission | Why |
| --- | --- |
| `android.permission.FOREGROUND_SERVICE` | Required to start any foreground service since Android 9 (API 28). |
| `android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE` | Required by Android 14 (API 34+) for the `connectedDevice` foreground service type. |
| `android.permission.POST_NOTIFICATIONS` | Android 13+ runtime permission so the persistent low-importance auto-record notification can render. Without it the service still runs but the channel is silenced. |
| `android.permission.BLUETOOTH_CONNECT` (already declared for #716) | Needed for `getRemoteDevice()` + `connectGatt()` on Android 12+. |

The service entry inside `<application>`:

```xml
<service
    android:name=".autorecord.AutoRecordForegroundService"
    android:exported="false"
    android:foregroundServiceType="connectedDevice"/>
```

## Why stock `BluetoothGatt`, not `flutter_blue_plus`?

`flutter_blue_plus` owns its own state machine that lives inside the
Flutter activity. Sharing one instance across an activity-less Android
service is fragile (the plugin's binding spans `FlutterEngine` plus
`FlutterPluginBinding.getApplicationContext`).

The service's only job is observing connect / disconnect; for that a
small stock GATT client with `connectGatt(autoConnect = true, ...)` is
the simpler and OS-blessed shape. Once the user opens the app, the
existing `FlutterBluePlusElmChannel` takes over for the actual ELM327
trip-recording session — there is no shared state to coordinate.

## Architecture

```
+-------------------+      MethodChannel       +-----------------------+
| Dart side         |  tankstellen/auto_record |                       |
| AndroidBackground |  /methods                |                       |
| AdapterListener   | -----------------------> |                       |
|                   |                          | BackgroundAdapter     |
|                   |  EventChannel            | Channel (Kotlin       |
|                   |  /events                 | singleton)            |
|                   | <----------------------- |                       |
+-------------------+                          +-----------+-----------+
                                                           |
                                                  startService(intent)
                                                           |
                                                           v
                                          +----------------------------+
                                          | AutoRecordForegroundService|
                                          |  - notification channel    |
                                          |    "auto_record"           |
                                          |  - BluetoothGatt callback  |
                                          |    autoConnect=true        |
                                          +----------------------------+
                                                           |
                                                           | connect / disconnect
                                                           |
                                                           v
                                            BackgroundAdapterChannel.post(...)
```

Connection events take the form `{"type": "connect" | "disconnect",
"mac": "<MAC>", "atMillis": <epoch ms>}`. The Dart-side listener
translates those maps into the sealed `AdapterConnected` /
`AdapterDisconnected` envelope that `AutoTripCoordinator` consumes.

## Test plan for the user

1. Install a build that has phase 2b-2 wiring (this PR is bridge-only,
   so the auto-record toggle in the consumption screen does not yet
   start the service).
2. Pair the OBD2 adapter once via Android settings.
3. Enable auto-record on the active vehicle profile.
4. Lock the phone, walk to the car, plug the adapter in (or step into
   range if it's permanently plugged).
5. Verify within ~60 s:
   * The persistent notification "Trip auto-record — Watching for your
     OBD2 adapter" is visible.
   * `AutoRecordTraceLog` shows a `connect` line for your MAC.
6. Drive for 5 minutes, then exit the car / turn off the ignition.
7. Verify:
   * `AutoRecordTraceLog` shows a `disconnect` line.
   * After the configured `disconnectSaveDelay` (default 60 s) the
     trip is saved to history.

## Production wiring (phase 2b-2)

`AutoRecordOrchestrator` (`lib/features/consumption/providers/auto_record_orchestrator.dart`)
is the single Riverpod-keepAlive provider that turns the foreground
service on. Boot sequence:

1. `AppInitializer._launch` reads `autoRecordOrchestratorProvider` from
   a post-first-frame microtask. Failures are logged but never block
   the launch path — a bug in the listener factory cannot crash boot.
2. The orchestrator subscribes to `vehicleProfileListProvider` and
   diffs every change. Any vehicle with both `autoRecord: true` and a
   non-null `pairedAdapterMac` gets a fresh `AutoTripCoordinator`.
3. The coordinator constructs its own `BackgroundAdapterListener`. On
   Android (`defaultTargetPlatform == TargetPlatform.android`) this is
   `AndroidBackgroundAdapterListener` — calling `start(mac)` triggers
   the Kotlin foreground service. On other platforms the orchestrator
   falls back to `UnimplementedBackgroundAdapterListener` so iOS /
   desktop builds still compile.
4. A vehicle that flips `autoRecord` off, drops its paired MAC, or
   gets deleted has its coordinator stopped. A `pairedAdapterMac`
   change is treated as drop + recreate: the foreground service
   watches a single MAC, so re-arming is the only way to switch.
5. Speed is sourced from `Geolocator.getPositionStream`
   (m/s → km/h) for phase 2b-2. Phase 2b-3 will switch to OBD2 PID
   0x0D once the on-connect session-handoff design is decided.
6. On orchestrator dispose (Riverpod container teardown / app exit)
   every coordinator is stopped, which in turn calls
   `AndroidBackgroundAdapterListener.stop()` and the foreground
   service is dismissed.

## Files

| Layer | Path |
| --- | --- |
| Service | `android/app/src/main/kotlin/de/tankstellen/tankstellen/autorecord/AutoRecordForegroundService.kt` |
| Bridge | `android/app/src/main/kotlin/de/tankstellen/tankstellen/autorecord/BackgroundAdapterChannel.kt` |
| Activity wiring | `android/app/src/main/kotlin/de/tankstellen/tankstellen/MainActivity.kt` |
| Manifest | `android/app/src/main/AndroidManifest.xml` |
| Dart bridge | `lib/features/consumption/data/obd2/android_background_adapter_listener.dart` |
| Coordinator | `lib/features/consumption/data/obd2/auto_trip_coordinator.dart` |
| Orchestrator | `lib/features/consumption/providers/auto_record_orchestrator.dart` |
| App boot | `lib/app/app_initializer.dart` |
| Tests | `test/features/consumption/data/obd2/android_background_adapter_listener_test.dart`, `test/features/consumption/providers/auto_record_orchestrator_test.dart` |
