# OBD2 Implementation

This page documents how Tankstellen talks to ELM327-based OBD2 Bluetooth adapters to read real-time engine data.

## Why the abstraction layers

Three stacked abstractions separate the ELM327 protocol from the Bluetooth plugin, and the Bluetooth plugin from the Dart code:

```
UI widget (obd2_adapter_picker.dart)
  │
  ▼
Obd2ConnectionService     (orchestration, state machine)
  │
  ▼
Obd2Service               (ELM327 init + PID reads)
  │
  ▼
Obd2Transport             (I/O contract)   ◄── Fakeable
  │
  ▼
ElmByteChannel            (byte pump)
  │
  ▼
BluetoothFacade           (plugin shim)   ◄── Fakeable
  │
  ▼
flutter_blue_plus         (package)
```

The top layers never import `flutter_blue_plus`, so tests inject a `FakeObd2Transport` (`obd2_transport.dart:21–43`) without any plugin dependency.

## Obd2Transport — the minimal I/O contract

`lib/features/consumption/data/obd2/obd2_transport.dart:6`

```dart
abstract class Obd2Transport {
  Future<void> connect();
  Future<String> sendCommand(String command);
  Future<void> disconnect();
  bool get isConnected;
}
```

`BluetoothObd2Transport` (`bluetooth_obd2_transport.dart:22`) is the real implementation. It wraps a generic `ElmByteChannel`, not a BLE-specific class, so the same transport works over Classic SPP. It buffers incoming chunks until the ELM327 prompt byte `0x3E` (`>`) arrives, then returns the trimmed response.

## Adapter registry

`lib/features/consumption/data/obd2/adapter_registry.dart`

Instead of a giant if-chain matching device names, the registry is a polymorphic lookup. Each entry is an `Obd2AdapterProfile` constant declaring:

- `id`, `displayName`, vendor
- Transport type (`bluetooth` BLE or `classicBluetooth` SPP)
- BLE service + characteristic UUIDs (for BLE adapters)
- Name-match patterns
- Optional `initDelay` (some clones need 300 ms between init commands)
- Optional `extraInitCommands` (e.g. `ATSP6\r` for Volvos)

Registered today (`adapter_registry.dart:189–263`):

| Adapter | Transport | Match |
|---|---|---|
| vLinker FS | Classic SPP | name contains "vlinker fs" |
| vLinker FD / MC | BLE (FFF0) | name + service UUID |
| OBDLink MX+ | BLE (custom 18F0) | service UUID |
| Carista OBD2 | BLE (Nordic UART) | name |
| Veepeak BLE+ | BLE (FFF0) | name |
| Generic ELM327 BLE | BLE (FFF0) | service UUID only |
| Generic ELM327 Classic | SPP | fallback |

### Resolution algorithm

```
for each scan hit:
  1. name-match pass   (strong signal)
  2. service-UUID pass (only for nameless profiles — avoids FFF0 clone
                        being assigned to the wrong branded profile)
  3. return null if nothing matches
```

Adding an adapter = appending one const `Obd2AdapterProfile` to `_defaultProfiles`. No other file changes.

## Connection lifecycle

`Obd2ConnectionService` (`obd2_connection_service.dart`) exposes two methods:

### `scan(Duration window)`
1. Requests runtime permissions via `Obd2Permissions.request()`. Throws `Obd2PermissionDenied` on refusal.
2. Merges BLE + Classic scan streams via `StreamGroup`.
3. Accumulates candidates by device ID, ranks via `registry.rank(scanHit)`.
4. On window expiry with no candidates → `Obd2ScanTimeout`.

Returns a stream of `ResolvedObd2Candidate { device, profile }`.

### `connect(candidate)`
1. Dispatches on candidate's transport type.
2. BLE → `PluginBluetoothFacade.connectBle(device, profile.uuids)` returns an `ElmByteChannel`.
3. Classic → `ClassicBluetoothFacade.connectSpp(device)` returns an `ElmByteChannel`.
4. Wraps the channel in a `BluetoothObd2Transport`.
5. Calls `Obd2Service.connect()` which runs the ELM327 init sequence.
6. Returns the ready `Obd2Service`.
7. On failure, closes the channel before rethrowing.

## ELM327 init sequence

`Obd2Service.connect()` (`obd2_service.dart:20–36`) sends:

```
ATZ       (reset)
ATE0      (echo off)
ATL0      (linefeeds off)
ATH0      (headers off)
ATSP0     (auto protocol)
```

Each with a 100 ms gap (the profile can override via `initDelay`). Any non-OK response throws `Obd2ProtocolInitFailed`.

## PIDs read

| PID | Meaning | Method |
|---|---|---|
| `01 0C` | Engine RPM | `readRpm()` |
| `01 0D` | Vehicle speed (km/h) | `readSpeedKmh()` |
| `01 04` | Engine load % | `readEngineLoad()` |
| `01 11` | Throttle position % | `readThrottlePercent()` |
| `01 10` | MAF (g/s) | `readMafGramsPerSecond()` |
| `01 5E` | Fuel rate (L/h) | `readFuelRateLPerHour()` (falls back to MAF-derived if unavailable) |
| `01 2F` | Fuel tank level % | `readFuelLevelPercent()` |
| `01 A6` | Odometer (km) | `readOdometerKm()` — primary |
| `01 31` | Distance since DTC clear | fallback |
| `22 xxxx` | Manufacturer-specific odometer via VIN | last-ditch fallback |

Odometer read (`obd2_service.dart:47–102`) is the most important — used to pre-fill fill-up entries. The three-level fallback covers ~95% of European cars 2010+.

## Permissions

`lib/features/consumption/data/obd2/obd2_permissions.dart`

Platform-gated:

| Android | Permissions | Why |
|---|---|---|
| 12+ (API 31+) | `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` | Split BLE model. `neverForLocation` in manifest → location is NOT requested. |
| 11 and below | `ACCESS_FINE_LOCATION` | OS-level requirement for BLE enumeration. App never actually reads location; this is a platform quirk. |
| iOS | returns `denied` | Not yet supported. |

States: `granted`, `denied`, `permanentlyDenied`. Aggregation: if any needed permission is permanently denied, the entire state is permanently denied → UI offers settings deep-link.

## Error hierarchy

`obd2_connection_errors.dart`:

```dart
sealed class Obd2ConnectionError {
  String get message;
}

class Obd2PermissionDenied extends Obd2ConnectionError    // Bluetooth perms refused
class Obd2ScanTimeout extends Obd2ConnectionError         // no adapter seen in window
class Obd2AdapterUnresponsive extends Obd2ConnectionError // connected but ELM init hung
class Obd2ProtocolInitFailed extends Obd2ConnectionError  // counterfeit chip
```

All carry a short localizable message for snackbars.

## UI integration

`obd2_adapter_picker.dart` exposes `showObd2AdapterPicker()` which returns a `Future<Obd2Service?>`. Internal state machine (`_Phase`):

```
scanning → selecting → connecting → { ready, error }
```

- **scanning** — spinner, `scan()` populating `ResolvedObd2Candidate` list
- **selecting** — ListTile per candidate, tap → `_connect(candidate)`
- **connecting** — spinner while `connect()` awaits
- **error** — icon + message + "Retry" button restarts scan

The service is injected via `obd2ConnectionProvider` (`obd2_connection_service.dart:135–143`), allowing tests to override with a fake that yields a preset candidate.

## Testing

Unit tests cover:
- `FakeObd2Transport` — roundtrip OK paths, error injection
- `AdapterRegistry.rank()` — every registered adapter has a "should-match" test and a "should-not-match" with a generic name
- `Obd2Service.connect()` — happy path + every error case
- Odometer read — all three fallback paths triggered with canned responses

Widget tests for `obd2_adapter_picker.dart` drive each `_Phase` via a fake `Obd2ConnectionService`.

## Auto-record orchestrator (Epic #2055-era)

`auto_trip_coordinator.dart` + `background_adapter_listener.dart` + the per-platform adapter listeners (`android_background_adapter_listener.dart`, `ios_state_restoration_service.dart`) together implement the fully hands-off recording flow:

1. **Adapter ↔ vehicle pairing** — the first manual pairing persists an `Obd2AdapterProfile` association on the active vehicle.
2. **Auto-connect on BLE proximity** — the OS-level Bluetooth listener fires `tankstellen/auto_record/methods.start(mac)` from native when the adapter advertises. The coordinator picks up the ELM channel without surfacing the picker UI.
3. **Auto-start on movement** — once the channel is up and GPS confirms motion, `TripRecordingController.startObd2()` runs unprompted.
4. **Auto-save on disconnect** — when the ELM byte channel reports the adapter has powered down, `paused_trip_recovery_service.dart` finalises and saves the trajet.

`auto_record_trace_log.dart` writes a Hive-backed event log of every state transition for diagnosability — when an auto-record run misbehaves, this is the first place to look.

> **iOS caveat (#1542):** the OS-level background wake required for "auto-connect when the adapter powers up after the app is killed" is still in progress. `ios_state_restoration_service.dart` ships today and handles the connection-side state restoration, but until #1542 lands the round-trip is not verified end-to-end. Android handles the full flow today.

## Fast reconnect

After a transient drop (LED blink, momentary out-of-range), the adapter ID and last-known service/characteristic UUIDs are cached, so reconnect skips the full scan + adapter-resolution dance. The flow:

1. `Obd2ConnectionService.connect()` records the resolved `Obd2AdapterProfile` against the device ID in a small Hive cache.
2. On reconnect attempt, the cache returns the profile in O(1) — no `scan()` window needed.
3. The byte channel re-opens, the ELM init sequence is re-run (`ATZ`, `ATE0`, ...), and live sampling resumes.

The cache is invalidated when the user manually unpairs or when init fails three times in a row (counterfeit chip likely).

## Roadmap

- **iOS auto-record background wake** (#1542) — the last piece needed to bring full hands-off parity to iOS.
- **Standard Mode 22 manufacturer PIDs** — currently only VW-group VIN hash is used; extending to Volvo, BMW, Renault packs would widen odometer coverage.

## Related

- [Testing & TDD](Dev-Testing-TDD-Pyramid) — how the fakes-over-mocks convention applies to OBD2 tests
- [Error Reporting & Tracing](Dev-Error-Reporting-Tracing) — how OBD2 errors surface to `TraceRecorder`
