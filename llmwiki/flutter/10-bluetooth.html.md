**10 · Device**

# Bluetooth & BLE

> Bluetooth is where a well-architected Flutter app usually meets its first genuinely hard problem. The API surface looks simple; the failure modes are timing-dependent, device-specific, and mostly invisible to unit tests. This page is a catalogue of the ones that cost real weeks.

**Chunk prefix** ble **Updated** 2026-08-01 **Depends on** 01 Foundations · 04 Robustness

#### On this page

1. [Two transports, two failure profiles](#transports)
1. [Permissions, by OS version](#permissions)
1. [One connection state machine](#state-machine)
1. [One reconnect authority](#ownership)
1. [The classic-RFCOMM reconnect hang](#rfcomm)
1. [Park, reuse and the dead-session trap](#park)
1. [Liveness on a stream that never errors](#liveness)
1. [Background execution limits](#background)
1. [A device registry, not a special case](#registry)
1. [Testing a device layer](#testing)

<!-- chunk: ble.transports | tags: bluetooth,ble,rfcomm,transport -->

## Two transports, two failure profiles

"Bluetooth" means two incompatible things, and a device that supports both will behave differently on each.

|   | BLE (GATT) | Classic (RFCOMM / SPP) |
| --- | --- | --- |
| Model | Services, characteristics, notifications | A serial stream over a single channel |
| Pairing | Usually none required | Usually system-paired first |
| iOS support | Yes, via Core Bluetooth | **No** for arbitrary devices (MFi programme only) |
| Throughput | Low; MTU-limited | Higher |
| Typical failure | Silent disconnect; notifications stop arriving | **Connect hangs indefinitely** — see [below](#rfcomm) |
| Timeout on connect | Plugin-provided | **None** on Android's `connect()` — you must impose one |

Many real-world dongles are **dual-mode**: they advertise both, and which one you get depends on how the user paired them. Detect the transport rather than assuming, and record it in the trace log on every connection — half of all "it worked yesterday" reports are actually "it connected over the other transport yesterday".

> **[RULE]**

> **Abstract the transport behind one interface and select it at runtime.** The rest of the app talks to a `DeviceLink` with connect / send / receive / disconnect. Which transport backs it is a detail of the link, discovered from the device. Without this seam, transport-specific behaviour leaks into the protocol layer and every fix has to be written twice.

<!-- chunk: ble.permissions | tags: permissions,android,ios,manifest -->

## Permissions, by OS version

Android's Bluetooth permission model changed twice and the old shape is still required on older API levels — so you declare all of them, with version gates.

```xml
<!-- Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 11 and below -->
<uses-permission android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30" />
<!-- Scanning implied location before API 31. Only if you must support it. -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30" />

<uses-feature android:name="android.hardware.bluetooth_le"
    android:required="false" />
```

> **[RULE]**

> **Declare `neverForLocation` on `BLUETOOTH_SCAN` if you do not derive location from scan results.** Without it the scan permission implies location access, which shows up in the store listing's permission summary and in the data-safety declaration — and users read both. With it, you can honestly declare that Bluetooth is not a location channel for your app.

iOS needs usage descriptions in `Info.plist`, and the wording is reviewed:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connects to your adapter to read live data from the device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Connects to your adapter to read live data from the device.</string>
```

> **[TRAP]**

> **Symptom: scanning returns nothing on one Android device and works on another, with permissions granted on both.** On many Android builds, BLE scanning requires *location services to be switched on system-wide* — not merely the location permission granted. The scan then succeeds and returns an empty list, with no error. Check the location-services state explicitly and tell the user to enable it; an empty scan result is indistinguishable from "no devices nearby" otherwise.

> **[CHECK]**

> Before debugging any scan problem, verify in this order: adapter powered on, permissions granted, location services on (Android), and the device actually advertising. Each has a distinct programmatic check. A scan layer that cannot report *which* of these failed will generate unactionable bug reports forever — the same three-state-availability argument made for NFC on [page 12](12-nfc-rfid.html#status).

<!-- chunk: ble.state-machine | tags: state-machine,architecture,connection -->

## One connection state machine

Model the link as an explicit state machine with named states and legal transitions. Boolean flags scattered across a controller cannot express "connecting but the user just cancelled", and that is exactly the state you will spend a week in.

```dart
enum LinkState {
  idle,          // no device selected
  scanning,
  connecting,
  handshaking,   // protocol init after transport is up
  ready,         // usable
  degraded,      // connected, but some capability is missing
  reconnecting,
  parked,        // deliberately held open but idle — see below
  failed,        // terminal for this attempt; carries a reason
}
```

| Property | Why it matters |
| --- | --- |
| Every transition is logged with its trigger | The trace is the only forensic record; a state change with no recorded cause is a dead end during triage |
| `failed` carries a typed reason | "Adapter off", "out of range", "protocol timeout" and "user cancelled" need different UI. A generic failure means a generic, useless message. |
| `degraded` exists at all | A device connected but missing a capability is a real and common state. Collapsing it into "connected" makes the resulting bad data inexplicable. |
| Illegal transitions throw in debug | Catches the class of bug where two code paths both drive the link |

> **[RULE]**

> **The state machine is the single source of truth for the UI.** No screen may infer connectivity from a side channel — a last-packet timestamp, a non-null session object, a boolean on a service. When two places can answer "are we connected", they will eventually disagree, and the UI will show a spinner over a working connection or a live reading over a dead one.

<!-- chunk: ble.ownership | tags: reconnect,concurrency,architecture -->

## One reconnect authority

Exactly one component may decide to reconnect. Two is the single most destructive architecture mistake available in this area.

> **[TRAP]**

> **Symptom: the app reconnects continuously during a session — connect traces appear 0–1 ms apart, alternating between two different initiators.** Two reconnect authorities existed: an app-wide "keep the device connected" service and a session-scoped "the recording lost its link" manager. Each saw the other's disconnect as a failure and re-initiated. The adapter was hammered, the session never stabilised, and the user-visible symptom — "permanently reconnecting" — pointed at the radio rather than at the architecture.

> **The tell:** connect attempts timestamped microseconds apart, with alternating source tags in the trace. If your traces do not carry a source tag on connection attempts, add one before doing anything else — it converts a week of guessing into a minute of reading.

> **The fix:** an explicit ownership latch. While a session owns the link, the app-wide service stands down entirely.

```dart
/// Exactly one owner may drive reconnection at a time.
class LinkOwnership {
  Object? _owner;

  bool acquire(Object who) {
    if (_owner != null && _owner != who) return false;
    _owner = who;
    TraceLogger.instance.info('ble', 'link owned by $who');
    return true;
  }

  void release(Object who) {
    if (_owner == who) {
      _owner = null;
      TraceLogger.instance.info('ble', 'link released by $who');
    }
  }

  bool mayReconnect(Object who) => _owner == null || _owner == who;
}
```

> **[RULE]**

> **Tag every connection attempt in the trace with its initiator.** One field. It is the difference between a diagnosable reconnect storm and an unexplainable one, and you cannot add it retroactively to a log that has already been collected from a user.

<!-- chunk: ble.rfcomm | tags: rfcomm,android,timeout,reconnect -->

## The classic-RFCOMM reconnect hang

> **[TRAP]**

> **Symptom: after a dropped classic connection, the next connect attempt hangs for 80–120 seconds before failing, with the native layer logging a repeated read error.** The adapter has a single serial channel, and the peer still considers it held after an abrupt drop. Android's `BluetoothSocket.connect()` has **no timeout parameter** and will block until the OS gives up — which can exceed two minutes. To the user, the app is frozen.

> **The fix is a watchdog, because the API gives you nothing else:**

> ```dart
> Future<DeviceLink> connectClassic(DeviceId id) async {
>   final attempt = _platform.connect(id);          // may block for minutes
>   try {
>     return await attempt.timeout(const Duration(seconds: 7));
>   } on TimeoutException {
>     // Abandon the socket, force-close it, let the stack release the
>     // channel, and try once more. A second failure is reported as a
>     // typed, actionable error — not a hang.
>     await _platform.forceClose(id);
>     await Future<void>.delayed(const Duration(milliseconds: 800));
>     return await _platform
>         .connect(id)
>         .timeout(const Duration(seconds: 7),
>                  onTimeout: () => throw const LinkError.channelHeld());
>   }
> }
> ```

> Seven seconds is empirical: a healthy classic connect completes in well under two, and anything past seven has essentially always failed. Tune against your own device population — but impose *a* timeout, because the platform will not.

Two supporting practices:

- **Always force-close before reconnecting**, even when you believe the socket is already gone. It is cheap and it releases the channel.
- **Surface the wait.** If a reconnect can take seven seconds, the UI must say "reconnecting" with a cancel affordance — not freeze. And per [page 04](04-robustness.html), an idle reconnect indicator should not blanket the whole app; a status dot carries it better than a full-width banner.

<!-- chunk: ble.park | tags: lifecycle,state-machine,bug -->

## Park, reuse and the dead-session trap

If you add a "parked" state to avoid tearing the link down between uses, you must also add the wake path — and prove something calls it.

> **[TRAP]**

> **Symptom: a feature that worked stops working after a refactor, with no error anywhere. The link reports connected; nothing arrives.** A park/reuse optimisation was added so the link survived between sessions. The `wake()` method that would revive a parked link **had zero callers**. The coordinator held a reference to a session that had been parked and then invalidated, so every command went into a dead object that dutifully accepted them.

> **Countermeasures, all three:**

1. **Grep for callers of every new lifecycle method before merging.** A public lifecycle method with no callers is either dead code or a missing wire-up, and both are bugs. This is [step 7 of the bug-fix protocol](03-tdd-and-testing.html#bugfix) applied at write time.
1. **Make a stale handle fail loudly.** A parked or disposed session must throw on use, not silently accept. A dead object that accepts commands is the worst possible failure mode because it produces no evidence at all.
1. **Add an integration test that exercises the full park → wake → use cycle**, not just the individual transitions.

> **[RULE]**

> **Validate device-layer fixes on hardware, on a build that actually contains them.** Both projects record device-layer fixes marked "needs on-device validation" that sat unvalidated across releases. A device-layer change is not done when CI is green — a headless test cannot observe a radio. Note the required validation explicitly in the pull request, and check the build number before concluding a fix did not work: a stale beta build is the most common cause of "still broken".

<!-- chunk: ble.liveness | tags: streams,watchdog,error-handling -->

## Liveness on a stream that never errors

Device streams commonly emit a sentinel on failure rather than erroring, which makes `onError` and `onDone` unreachable — so liveness must ride the data path.

> **[TRAP]**

> **Symptom: a watchdog never fires even though the device is plainly gone.** A telemetry stream designed to emit `null` on a failed read, and to keep polling forever, never errors and never closes. Every callback-based liveness check attached to it is dead code. See [page 04](04-robustness.html#streams) for the general form; the fix is an in-band tick counter:

> ```dart
> sub = telemetry.listen((sample) {
>   if (sample == null && !_link.isConnected) {
>     if (++_missed > _threshold) _handleLoss();
>   } else {
>     _missed = 0;
>     _onSample(sample);
>   }
> });
> ```

> **[TRAP]**

> **Symptom: an uncaught "transport closed" error crashes an isolate at startup.** A pending completer was completed with an error before any listener had attached. Dart treats an error delivered to a future or stream with no listener as unhandled. When you complete a pending operation with an error during teardown, either attach a no-op handler at creation time or check for listeners before completing — and prefer completing with a typed *value* representing the failure over completing with an error, for exactly this reason.

<!-- chunk: ble.background | tags: background,android,ios,foreground-service -->

## Background execution limits

What a Bluetooth connection can do with the screen off is entirely different on the two platforms, and neither behaves the way the desktop mental model suggests.

|   | Android | iOS |
| --- | --- | --- |
| Keep a connection alive in background | Yes, with a foreground service and its notification | Yes for BLE, with the `bluetooth-central` background mode |
| Wake the app when a known device appears | Yes, via a scan with a pending intent | Yes, state-restoration relaunches the app for a known peripheral |
| Sustained processing while backgrounded | Yes, in the foreground service | **Severely limited** — brief windows only |
| Classic RFCOMM | Yes | **Not available** outside the MFi programme |
| Store paperwork | A foreground-service declaration form | Background-mode entitlements, reviewed |

> **[TRAP]**

> **Symptom: location and sensor callbacks arrive in ~5-second batches instead of continuously once the screen is off.** Android batches background delivery aggressively. A foreground service is the documented lever, but declaring one now requires a store-approved justification — and until that is approved, shipping the permission can block your release upload entirely. One project handles this with a single build-time flag that flips *both* halves in lockstep: the Dart code that requests the foreground service, and the manifest overlay that declares the permissions. The default build ships with zero foreground-service permissions so uploads never fail; one flag restores the whole feature once the paperwork clears. See [page 13](13-android.html#fgs).

> **[RULE]**

> **Design the feature to degrade to foreground-only, and say so in the UI.** Background device work is a privilege granted by two operating systems and two review teams, any of which can withdraw it. A feature that is worthless without it is a feature built on someone else's policy.

<!-- chunk: ble.registry | tags: devices,configuration,compatibility -->

## A device registry, not a special case

Real hardware varies. Put the variation in data — a registry keyed by advertised name, manufacturer id or service UUID — rather than in branches.

```dart
class AdapterProfile {
  const AdapterProfile({
    required this.matcher,          // name pattern / service UUID
    required this.transport,        // ble | classic | dual
    required this.initSequence,     // protocol handshake commands
    this.connectTimeout = const Duration(seconds: 7),
    this.requiresPairing = false,
    this.knownQuirks = const <String>[],
  });
}
```

What belongs in the registry: the transport, the handshake, timeouts, whether system pairing is required, unsupported capabilities, and known quirks with a human-readable note. What does *not* belong: anything the device can be asked at runtime — always prefer interrogation over a hard-coded assumption, and fall back to the registry only for what cannot be discovered.

> **[WHY]**

> Support becomes a data change instead of a code change. A user reports a dongle that will not connect; you add an entry with the right transport and timeout and ship it in the next release without touching the link layer. Publishing the registry as documentation also lets users check compatibility before buying — one project maintains exactly such a page, and it measurably reduces the support load.

<!-- chunk: ble.testing | tags: testing,fakes,replay -->

## Testing a device layer

You cannot unit-test a radio. You can test everything on either side of it, and that turns out to be most of what breaks.

| Layer | How | Catches |
| --- | --- | --- |
| **Protocol codec** | Pure unit tests over recorded byte frames | Parsing, framing, checksums, malformed input |
| **State machine** | Unit tests driving transitions directly | Illegal transitions, stuck states, missing wake paths |
| **Link behaviour** | A fake transport with scripted delays, drops and garbage | Timeouts, retry logic, the reconnect storm |
| **Session replay** | Replay a captured real session through the real stack | Regressions in decoding and in session lifecycle |
| **On device** | A manual checklist per release | Everything else |

```dart
/// A transport fake that can misbehave the way real hardware does.
class ScriptedTransport implements DeviceTransport {
  ScriptedTransport(this.script);
  final List<TransportEvent> script;   // delay, bytes, drop, hang, garbage

  @override
  Future<void> connect() async {
    final e = script.removeAt(0);
    if (e.hangs) await Future<void>.delayed(const Duration(minutes: 2));
    if (e.fails) throw const LinkError.unreachable();
  }
}
```

> **[CHECK]**

> Three scripted scenarios worth having permanently, because each maps to a trap on this page: **(1)** connect hangs, then succeeds on retry — asserts the watchdog fires and the retry works; **(2)** a mid-session drop while a second component also wants the link — asserts exactly one reconnect authority acts; **(3)** the stream emits sentinels forever without erroring — asserts the in-band liveness check fires.

Keep a written on-device checklist for each release: cold connect, warm reconnect, mid-session drop and recovery, adapter powered off during use, phone Bluetooth toggled during use, backgrounded for five minutes, and device out of range and returning. Seven scenarios, ten minutes, and they cover the failures the automated suite structurally cannot reach.

#### Sources for this page

- One project's OBD-II link layer and its rewrite epic: the dual-mode adapter registry, the published adapter-compatibility guide, the link-ownership latch, the 7-second RFCOMM watchdog, the park/reuse dead-session incident, the never-erroring telemetry stream, and the unhandled "transport closed" completer error.
- The same project's foreground-service gating: one build-time flag flipping both the Dart request and the manifest overlay, defaulting to zero foreground-service permissions.
- Its recorded reconnect-storm diagnosis, including the identifying signature of alternating sub-millisecond connect traces.

The `LinkOwnership`, `AdapterProfile` and `ScriptedTransport` snippets are illustrative reconstructions of the described designs. The iOS/Android background-capability table is standard platform behaviour, included because it constrains what the rest of the page can promise.
