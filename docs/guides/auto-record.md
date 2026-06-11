<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Hands-free trip auto-record (Android)

Status: phase 2b-3 — `AutoTripCoordinator` wired to the active vehicle
list via `AutoRecordOrchestrator`, speed sourced from OBD2 PID 0x0D.

**The foreground-service `<service>` entry is currently commented out in
the manifest** pending the Google Play "Foreground Service Use" form
(#1498), so the OS-level background bridge does not run in shipped
builds yet. While it is disabled, the **foreground-active arming
fallback** (#2282 concern 1) drives engine-start detection from the
live Flutter engine whenever the app is resumed: on every app resume the
orchestrator opens a direct connect (`connectByMacDirect`) to the paired
adapter and the coordinator watches PID 0x0D for movement. The native
foreground service below is the backgrounded-detection path that the
form approval will re-enable.

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

The service entry inside `<application>` (currently commented out —
restore it alongside the `FOREGROUND_SERVICE*` permissions once the
Play "Foreground Service Use" form #1498 is approved):

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

While the foreground service is disabled in the manifest, only the
**foreground-active** path (app open) is exercisable; the
backgrounded/locked-phone steps below apply once the service is
re-enabled.

1. Pair the OBD2 adapter once (via the in-app picker or Android
   settings) so the active vehicle has an `obd2AdapterMac`.
2. Enable auto-record on the active vehicle profile.
3. Foreground-active path: with the app open, get in and start driving.
   Within a few seconds of crossing the movement threshold,
   `AutoRecordTraceLog` shows a `foregroundArmAttempt` followed by
   `thresholdCrossed` → `tripStarted` and the recording banner appears.
4. (Backgrounded path — once the service is re-enabled) Lock the phone,
   walk to the car, plug the adapter in. Verify within ~60 s the
   persistent "Trip auto-record" notification is visible and
   `AutoRecordTraceLog` shows a `connect` line for your MAC.
5. Drive for 5 minutes, then exit the car / turn off the ignition.
6. Verify `AutoRecordTraceLog` shows a `disconnect` line and, after the
   configured `disconnectSaveDelay` (default 60 s), the trip is saved to
   history.

## Production wiring

`AutoRecordOrchestrator` (`lib/features/consumption/providers/auto_record_orchestrator.dart`)
is the single Riverpod-keepAlive provider that drives the hands-free
flow. Boot sequence:

1. `AppInitializer._launch` reads `autoRecordOrchestratorProvider` from
   a post-first-frame microtask. Failures are logged but never block
   the launch path — a bug in the listener factory cannot crash boot.
2. The orchestrator subscribes to `vehicleProfileListProvider` and
   diffs every change. Any vehicle with both `autoRecord: true` and a
   non-null `obd2AdapterMac` (via `autoRecordAdapterMac`) gets a fresh
   `AutoTripCoordinator`. Before arming, the orchestrator requests
   runtime `POST_NOTIFICATIONS` (#2282 concern 2).
3. The coordinator constructs its own `BackgroundAdapterListener`. On
   Android (`defaultTargetPlatform == TargetPlatform.android`) this is
   `AndroidBackgroundAdapterListener` — `start(mac)` would trigger the
   Kotlin foreground service (currently disabled in the manifest, so a
   no-op until #1498). On other platforms the orchestrator falls back to
   `UnimplementedBackgroundAdapterListener` so iOS / desktop builds
   still compile.
4. Foreground-active arming (#2282 concern 1): the orchestrator owns an
   `AppLifecycleListener` whose `onResume` asks every active coordinator
   to `armForegroundActive()` — a direct `connectByMacDirect` to the
   paired adapter from the live engine. This is the path that works
   today while the foreground service is disabled.
5. A vehicle that flips `autoRecord` off, drops its paired MAC, or
   gets deleted has its coordinator stopped. An `obd2AdapterMac`
   change is treated as drop + recreate: the foreground service
   watches a single MAC, so re-arming is the only way to switch.
6. Speed is sourced from OBD2 PID 0x0D (phase 2b-3): on connect the
   coordinator opens an `Obd2Service` for the paired MAC, polls PID 0x0D
   at 1 Hz via `Obd2SpeedStream`, and hands the live session to
   `TripRecording.start` on threshold-cross. The BLE link is dropped to
   balanced connection priority while only that 1 Hz movement stream is
   live and restored to high on hand-off (#2282 concern 4).
7. On orchestrator dispose (Riverpod container teardown / app exit)
   every coordinator is stopped, which in turn calls
   `AndroidBackgroundAdapterListener.stop()` (and the foreground service
   is dismissed when it is enabled). The `AppLifecycleListener` is also
   disposed.

## Files

| Layer | Path |
| --- | --- |
| Service | `android/app/src/main/kotlin/de/tankstellen/tankstellen/autorecord/AutoRecordForegroundService.kt` |
| Bridge | `android/app/src/main/kotlin/de/tankstellen/tankstellen/autorecord/BackgroundAdapterChannel.kt` |
| Activity wiring | `android/app/src/main/kotlin/de/tankstellen/tankstellen/MainActivity.kt` |
| Manifest | `android/app/src/main/AndroidManifest.xml` |
| Dart bridge | `lib/features/obd2/data/android_background_adapter_listener.dart` |
| Coordinator | `lib/features/obd2/data/auto_trip_coordinator.dart` |
| Orchestrator | `lib/features/consumption/providers/auto_record_orchestrator.dart` |
| App boot | `lib/app/app_initializer.dart` |
| Tests | `test/features/obd2/data/android_background_adapter_listener_test.dart`, `test/features/consumption/providers/auto_record_orchestrator_test.dart` |
