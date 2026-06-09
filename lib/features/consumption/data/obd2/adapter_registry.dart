// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'adapters/smart_obd_adapter.dart';
import 'adapters/v_linker_fs_adapter.dart';
import 'elm327_adapter.dart';
import 'elm327_protocol.dart';

/// Per-adapter verification status (#1371). Documents how confident
/// we are that a given profile actually drives the adapter end-to-end
/// on a real device — separate from "is it listed in the picker".
///
/// Used by the docs/wiki to surface a "tested vs theoretical" matrix
/// to users before they buy. Defaults to [theoretical] so adding a
/// new entry stays conservative until someone verifies it.
enum Obd2AdapterCompatibility {
  /// Maintainer has confirmed the adapter works on their device:
  /// scan → connect → live PID stream all green.
  tested,

  /// At least one user reported success but the variant is ambiguous
  /// (e.g. the same hardware ships both BLE and Classic transports
  /// and the report didn't pin down which one was used).
  userVerified,

  /// No verification yet. Expected to work because the matchers /
  /// service UUIDs identify a known ELM327 family (Nordic UART FFF0,
  /// SPP Classic, etc.), but never connected to in anger.
  theoretical,

  /// Listed but no information either way. Use sparingly — most
  /// entries should be [theoretical] or better.
  untested,
}

/// Thin value-object describing one scan result. Kept
/// flutter_blue_plus-free so the registry can be unit-tested without
/// the platform plugin (the real connection service converts
/// `ScanResult` / a bonded-device entry into this shape at the edge).
/// Step 1 of #733.
class Obd2AdapterCandidate {
  /// Platform device id (MAC address on Android, UUID on iOS).
  final String deviceId;

  /// Friendly name reported by the advertisement. Empty when the
  /// adapter only advertises anonymous iBeacon data.
  final String deviceName;

  /// Service UUIDs the adapter advertises, lower-cased with dashes.
  /// Normalised on construction so matching is order- and case-free.
  final Set<String> advertisedServiceUuids;

  /// Received Signal Strength Indicator in dBm. Closer adapters have
  /// values closer to 0 (e.g. -50 is stronger than -90).
  final int rssi;

  /// Which transport actually discovered this candidate (#3097). The BLE
  /// facade stamps [BluetoothTransport.ble]; the Classic (bonded-device)
  /// facade stamps [BluetoothTransport.classic]. [resolve] reads it to
  /// disambiguate a generic name (e.g. `OBDII`) that matches BOTH a BLE and
  /// a Classic profile: a BLE-discovered hit must resolve to a BLE profile
  /// (so it connects over BLE — the only transport iOS can use for a
  /// non-MFi adapter), and a Classic-discovered hit on Android must still
  /// resolve to Classic. Defaults to [BluetoothTransport.ble] — the
  /// dominant over-the-air scan transport, and the historical assumption of
  /// this BLE-first value object.
  final BluetoothTransport discoveryTransport;

  Obd2AdapterCandidate({
    required this.deviceId,
    required this.deviceName,
    required Iterable<String> advertisedServiceUuids,
    required this.rssi,
    this.discoveryTransport = BluetoothTransport.ble,
  }) : advertisedServiceUuids = advertisedServiceUuids
            .map((u) => u.trim().toLowerCase())
            .toSet();
}

/// Which Bluetooth transport an adapter uses (#761).
///
/// * [ble] — GATT / BLE peripheral. Discovered via `flutter_blue_plus`
///   scan, communicates via write + notify characteristics.
/// * [classic] — Bluetooth Classic (BR/EDR) with the Serial Port
///   Profile (SPP). Not discoverable via BLE scan; enumerated from
///   Android's bonded-device list and accessed via an RFCOMM socket.
enum BluetoothTransport { ble, classic }

/// One supported ELM327-compatible adapter. Selected by the registry
/// based on name substring + advertised service UUIDs (BLE) or just
/// device name (Classic, since Classic devices don't advertise).
class Obd2AdapterProfile {
  /// Stable internal id, used when persisting the last-connected
  /// adapter to Hive (`vlinker-fs`, `obdlink-mx`, `generic-fff0`, …).
  final String id;

  /// Marketing name shown in the picker.
  final String displayName;

  /// Transport this adapter uses — determines which facade
  /// [Obd2ConnectionService] dispatches to.
  final BluetoothTransport transport;

  /// BLE service/characteristic UUIDs this adapter exposes. Only
  /// meaningful when [transport] is [BluetoothTransport.ble]. For
  /// [BluetoothTransport.classic] adapters these fields are ignored
  /// (SPP uses a fixed UUID).
  final String serviceUuid;
  final String writeCharUuid;
  final String notifyCharUuid;

  /// Substrings matched case-insensitively against the device name
  /// to auto-detect this profile during a scan. Empty for a
  /// generic-fallback profile that has no naming signature.
  final List<String> nameMatchers;

  /// Per-adapter ELM327 protocol quirks (#1330): init sequence,
  /// timing, response pre-parse hook. Phase 2 ships
  /// [GenericElm327Adapter] as the default, [VLinkerFsAdapter] for
  /// vLinker FS-class adapters, and [SmartObdAdapter] for SmartOBD
  /// clones (which need longer delays + a stray-`>` preParse).
  final Elm327Adapter adapter;

  /// Verification tier for this profile (#1371). Defaults to
  /// [Obd2AdapterCompatibility.theoretical] so new entries are
  /// conservative until someone confirms the adapter on a real
  /// device. Surface this in the docs/wiki matrix — never gate
  /// runtime behaviour on it.
  final Obd2AdapterCompatibility compatibility;

  const Obd2AdapterProfile({
    required this.id,
    required this.displayName,
    this.transport = BluetoothTransport.ble,
    this.serviceUuid = '',
    this.writeCharUuid = '',
    this.notifyCharUuid = '',
    this.nameMatchers = const [],
    this.adapter = const GenericElm327Adapter(),
    this.compatibility = Obd2AdapterCompatibility.theoretical,
  });

  /// Compares service uuid against the advertised set, case-insensitive.
  bool matchesAdvertisedServices(Set<String> advertised) =>
      advertised.contains(serviceUuid.toLowerCase());

  /// Compares the device name against [nameMatchers].
  bool matchesName(String deviceName) {
    if (deviceName.isEmpty || nameMatchers.isEmpty) return false;
    final lower = deviceName.toLowerCase();
    return nameMatchers.any((m) => lower.contains(m.toLowerCase()));
  }
}

/// Catalog of known BLE adapter profiles + a resolver that picks
/// the best match for a scan hit.
///
/// Resolution order (first hit wins):
///   1. Exact name match against [Obd2AdapterProfile.nameMatchers].
///   2. Advertised service UUID matches [Obd2AdapterProfile.serviceUuid].
///   3. The generic fallback — returned for any ELM327 clone that
///      advertises the FFF0 service but has an unfamiliar name.
///
/// The fallback is intentionally conservative: if a candidate matches
/// neither a named profile nor a known service, [resolve] returns
/// null and the UI hides the candidate from the picker.
class Obd2AdapterRegistry {
  final List<Obd2AdapterProfile> profiles;

  const Obd2AdapterRegistry({required this.profiles});

  /// Default catalog bundled with the app. Add an entry here to
  /// support a new adapter; no other code change needed.
  factory Obd2AdapterRegistry.defaults() =>
      const Obd2AdapterRegistry(profiles: _defaultProfiles);

  /// All BLE service UUIDs the registry knows about. Classic profiles are
  /// excluded — SPP uses a single universal UUID and Classic discovery
  /// doesn't filter by service anyway.
  ///
  /// #3097 — this is **no longer** handed to `startScan(withServices:)`. The
  /// scan now runs UNFILTERED: on iOS, CoreBluetooth only returns peripherals
  /// that ADVERTISE one of these UUIDs, but most ELM327 BLE clones advertise a
  /// NAME and no service UUID, so a service-filtered scan returned nothing on
  /// iPhone. [resolve] already drops non-adapter noise (returns null → the
  /// picker hides it), so the scan-level filter was both redundant and
  /// iOS-starving. Retained only for reference / tests.
  Set<String> get allServiceUuids => profiles
      .where((p) => p.transport == BluetoothTransport.ble)
      .map((p) => p.serviceUuid.toLowerCase())
      .where((u) => u.isNotEmpty)
      .toSet();

  /// Pick the best profile for [candidate]. Returns null when the
  /// candidate is clearly not an OBD2 adapter.
  Obd2AdapterProfile? resolve(Obd2AdapterCandidate candidate) {
    // Pass 1: named match. A named profile wins over a generic one
    // if the advertised name carries its signature.
    //
    // #3097 — when a name matches profiles of MORE THAN ONE transport (e.g. a
    // generic `OBDII` matches both `generic-ble` and `generic-classic`, or a
    // `SmartOBD` matches both `smartobd-ble` and `smartobd-classic`), prefer
    // the profile whose transport == the candidate's discovery transport. A
    // BLE-discovered generic adapter must resolve to a BLE profile so it
    // connects over BLE (the only transport iOS can use for a non-MFi
    // adapter); a Classic-discovered one on Android must still resolve to
    // Classic (no regression). A single-transport name match is unaffected:
    // the first matcher in catalog order wins, exactly as before.
    final named = [
      for (final p in profiles)
        if (p.matchesName(candidate.deviceName)) p,
    ];
    if (named.isNotEmpty) {
      final transports = named.map((p) => p.transport).toSet();
      if (transports.length > 1) {
        for (final p in named) {
          if (p.transport == candidate.discoveryTransport) return p;
        }
      }
      // Single transport, or no profile matched the discovery transport
      // (defensive) — keep the historical first-in-catalog-order winner.
      return named.first;
    }
    // Pass 2: service UUID match, but only against generic/nameless
    // profiles. Named profiles require their name to be seen —
    // otherwise a random clone advertising the FFF0 service would be
    // mis-labelled. Classic profiles are skipped here: they have no
    // advertised services and are reached only via pass 1 (name).
    for (final p in profiles) {
      if (p.nameMatchers.isNotEmpty) continue;
      if (p.transport != BluetoothTransport.ble) continue;
      if (p.matchesAdvertisedServices(candidate.advertisedServiceUuids)) {
        return p;
      }
    }
    // Pass 3: nothing looks like an OBD2 adapter — let the UI hide it.
    return null;
  }

  /// Infer the [BluetoothTransport] for a stored adapter [name] (#2969) by
  /// matching it against every profile's [Obd2AdapterProfile.nameMatchers]. A
  /// paired adapter stores only its MAC + name (no transport), so the
  /// transport-aware self-test recovers it here: a name like `vLinker FS 1234`
  /// matches the `vlinker-fs-classic` profile → [BluetoothTransport.classic],
  /// so the self-test takes the RFCOMM path instead of a doomed BLE 4 s-timeout.
  ///
  /// Returns null when no profile name-matches (an unfamiliar adapter), so the
  /// caller can record an explicit "no hint — defaulting to BLE" decision
  /// rather than silently guessing. First name-match wins (same order as
  /// [resolve]'s pass 1).
  BluetoothTransport? transportForName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final p in profiles) {
      if (p.matchesName(name)) return p.transport;
    }
    return null;
  }

  /// #3014 — the DISTINCT transports a stored [name] name-matches. A name like
  /// `SmartOBD` matches BOTH `smartobd-ble` and `smartobd-classic`, so the
  /// hardware ships in two transports under one name — the dual-transport
  /// ambiguity [transportForName] silently resolves BLE-first. Empty when no
  /// profile matches.
  Set<BluetoothTransport> transportsForName(String? name) {
    if (name == null || name.isEmpty) return const {};
    return {
      for (final p in profiles)
        if (p.matchesName(name)) p.transport,
    };
  }

  /// #3014 — dual-transport disambiguation for a by-MAC / self-test connect.
  /// When [name] name-matches BOTH a BLE and a Classic profile (e.g. SmartOBD,
  /// vLinker), prefer the bonded-Classic path when [macIsBonded] (a bonded
  /// RFCOMM socket is the most reliable link for a dual-transport adapter that
  /// is paired in OS settings), else BLE. A single-transport match returns that
  /// transport unchanged; no match returns null. The runtime cross-transport
  /// fallback (#2908) still corrects a wrong guess, so this is a best-FIRST
  /// pick, not a hard commitment.
  BluetoothTransport? disambiguateTransport({
    required String? name,
    required bool macIsBonded,
  }) {
    final matched = transportsForName(name);
    if (matched.isEmpty) return null;
    final dualMatch = matched.contains(BluetoothTransport.ble) &&
        matched.contains(BluetoothTransport.classic);
    if (dualMatch) {
      return macIsBonded
          ? BluetoothTransport.classic
          : BluetoothTransport.ble;
    }
    return matched.first;
  }

  /// Rank a list of candidates for display in the picker. Primary
  /// key: resolved-profile-matched first (unresolved dropped). Secondary
  /// key: stronger RSSI (closer adapter) first.
  List<ResolvedObd2Candidate> rank(List<Obd2AdapterCandidate> candidates) {
    final resolved = <ResolvedObd2Candidate>[];
    for (final c in candidates) {
      final profile = resolve(c);
      if (profile == null) continue;
      resolved.add(ResolvedObd2Candidate(candidate: c, profile: profile));
    }
    resolved.sort((a, b) => b.candidate.rssi.compareTo(a.candidate.rssi));
    return resolved;
  }
}

/// Pair of a scan hit with the adapter profile the registry matched
/// to it. The picker UI uses this shape directly.
class ResolvedObd2Candidate {
  final Obd2AdapterCandidate candidate;
  final Obd2AdapterProfile profile;
  const ResolvedObd2Candidate({
    required this.candidate,
    required this.profile,
  });
}

/// Default profile catalog. Kept as a const list so the registry is
/// a cheap static-data lookup — no I/O to construct it.
const List<Obd2AdapterProfile> _defaultProfiles = [
  // vLinker FS / MS — Bluetooth CLASSIC variant (#761). The FS is the
  // dominant Amazon-EU model; the user-reported adapter in the field
  // advertises as "vLinker FS ####" over Classic SPP. Paired via the
  // OS Bluetooth settings; our scan enumerates bonded devices.
  Obd2AdapterProfile(
    id: 'vlinker-fs-classic',
    displayName: 'vLinker FS (Classic)',
    transport: BluetoothTransport.classic,
    nameMatchers: ['vlinker fs', 'vlinker ms', 'vlink fs', 'vgate fs'],
    adapter: VLinkerFsAdapter(),
    compatibility: Obd2AdapterCompatibility.tested,
  ),
  // vLinker FD / MC — the BLE variants. Nordic UART: FFF0 service,
  // FFF2 write, FFF1 notify. Name advertises as "vLinker FD" / "MC".
  Obd2AdapterProfile(
    id: 'vlinker-ble',
    displayName: 'vLinker FD / MC (BLE)',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['vlinker fd', 'vlinker mc', 'vlink fd', 'vlink mc'],
  ),
  // OBDLink MX+ — Scantool's premium STN-chip adapter, custom service
  // UUID pair. The matcher is the model-specific "obdlink mx" so the
  // LX / CX siblings below get their own profiles (#1641).
  Obd2AdapterProfile(
    id: 'obdlink-mx',
    displayName: 'OBDLink MX+',
    serviceUuid: '000018f0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '00002af1-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '00002af0-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['obdlink mx'],
  ),
  // OBDLink LX — Scantool's mid-range STN-chip BLE adapter (#1641).
  // Same custom 18F0 service family as the MX+.
  Obd2AdapterProfile(
    id: 'obdlink-lx',
    displayName: 'OBDLink LX',
    serviceUuid: '000018f0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '00002af1-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '00002af0-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['obdlink lx'],
  ),
  // OBDLink CX — Scantool's newest STN-chip BLE adapter, CAN-FD
  // capable, popular with BMW owners (#1641).
  Obd2AdapterProfile(
    id: 'obdlink-cx',
    displayName: 'OBDLink CX',
    serviceUuid: '000018f0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '00002af1-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '00002af0-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['obdlink cx'],
  ),
  // Carista OBD2 — Nordic UART like vLinker but advertises as
  // "Carista" so it gets its own named profile.
  Obd2AdapterProfile(
    id: 'carista',
    displayName: 'Carista OBD2',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['carista'],
  ),
  // Veepeak BLE+ — ELM327 clone, same FFF0 profile. Advertises as
  // "Veepeak" or "VEEPEAK OBD".
  Obd2AdapterProfile(
    id: 'veepeak',
    displayName: 'Veepeak BLE+',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['veepeak'],
  ),
  // SmartOBD — generic ELM327 v1.5 clone, widely shipped on Amazon
  // (#949). BLE variant rides on FFF0 like the rest of the Nordic-UART
  // family; a Classic-BT sibling also exists under the same name, so a
  // separate Classic entry follows this one.
  Obd2AdapterProfile(
    id: 'smartobd-ble',
    displayName: 'SmartOBD (BLE)',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['smartobd'],
    adapter: SmartObdAdapter(),
    // Maintainer-confirmed the SmartOBD hardware works, but the
    // bonded device list surfaces the same name for both transports
    // and the maintainer's session didn't pin which one carried the
    // live PID stream — flag both BLE+Classic as userVerified (#1371).
    compatibility: Obd2AdapterCompatibility.userVerified,
  ),
  Obd2AdapterProfile(
    id: 'smartobd-classic',
    displayName: 'SmartOBD (Classic)',
    transport: BluetoothTransport.classic,
    nameMatchers: ['smartobd'],
    adapter: SmartObdAdapter(),
    compatibility: Obd2AdapterCompatibility.userVerified,
  ),
  // ieGeek Scanner — ELM327 v2.1 BLE clone, advertises as "ieGeek…"
  // (#949). Nordic UART FFF0 family.
  Obd2AdapterProfile(
    id: 'iegeek',
    displayName: 'ieGeek Scanner',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['iegeek'],
  ),
  // vLinker BM+ — BLE-only sibling of the vLinker BM. The "+" is the
  // distinguishing glyph, so the matchers require it to win over a
  // future plain-"bm" entry; listed as 'vlinker bm+' / 'vlink bm+'
  // (#949). Same Nordic UART FFF0 family.
  Obd2AdapterProfile(
    id: 'vlinker-bm-plus',
    displayName: 'vLinker BM+ (BLE)',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['vlinker bm+', 'vlink bm+'],
  ),
  // vLinker BM-Android — Classic SPP firmware variant of the vLinker
  // BM line that ships with an Android-specific advertising name
  // (#1349). User-reported on a Samsung device 2026-05-02: bonded
  // device list shows "vLinker BM-Android" and the picker hid it
  // because no profile carried a matcher for the "-android" suffix
  // (the BM+ entry above requires the literal "+", and the generic
  // Classic fallback only catches names containing "obd" / "elm327").
  // Listed BEFORE the generic-classic fallback so this specific
  // match wins. The Android-suffixed name is the conservative match —
  // a plain "vLinker BM" Classic device would still need its own
  // entry, but evidence in the field is for the -Android variant.
  Obd2AdapterProfile(
    id: 'vlinker-bm-android-classic',
    displayName: 'vLinker BM-Android (Classic)',
    transport: BluetoothTransport.classic,
    nameMatchers: ['vlinker bm-android', 'vlink bm-android'],
    compatibility: Obd2AdapterCompatibility.tested,
  ),
  // Konnwei KW902 — Classic Bluetooth ELM327 v1.5 clone, extremely
  // common on Amazon / AliExpress. Advertises as "KONNWEI" or "KW902"
  // in bonded-device lists (#949).
  Obd2AdapterProfile(
    id: 'konnwei-kw902',
    displayName: 'Konnwei KW902',
    transport: BluetoothTransport.classic,
    nameMatchers: ['konnwei', 'kw902'],
  ),
  // Vgate iCar Pro — Chinese-brand ELM327, ships in BLE and WiFi
  // variants (#949). The BLE model lands on the FFF0 Nordic-UART
  // family; the WiFi model is handled by a TCP adapter outside this
  // registry. Name advertises as "Vgate iCar Pro" / "iCar Pro".
  Obd2AdapterProfile(
    id: 'vgate-icar-pro',
    displayName: 'Vgate iCar Pro',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['vgate', 'icar pro'],
  ),
  // Panlong WiFi — entry-level WiFi adapter (#949). Not reachable via
  // BLE scan, but a Classic-bonded-device list may still carry the
  // name if the user mis-paired it; keep the matcher available so the
  // UI labels the device correctly before the connection attempt
  // fails. Transport set to classic as the nearest no-op (WiFi
  // adapters connect through a TCP facade).
  Obd2AdapterProfile(
    id: 'panlong-wifi',
    displayName: 'Panlong WiFi',
    transport: BluetoothTransport.classic,
    nameMatchers: ['panlong'],
  ),
  // BAFX 34t5 — legacy ELM327 v1.5 Classic-BT adapter, still widely
  // sold in the US (#949). Advertises simply as "BAFX".
  Obd2AdapterProfile(
    id: 'bafx',
    displayName: 'BAFX 34t5',
    transport: BluetoothTransport.classic,
    nameMatchers: ['bafx'],
  ),
  // BlueDriver (Lemur Vehicle Monitors) — premium BLE scan tool, a
  // long-running Amazon best-seller (#1641). Rides the Nordic-UART
  // FFF0 family; theoretical until verified on a real device.
  Obd2AdapterProfile(
    id: 'bluedriver',
    displayName: 'BlueDriver',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['bluedriver'],
  ),
  // PLX Kiwi 3 — long-lived premium BLE ELM327-compatible adapter
  // (#1641). Advertises as "Kiwi".
  Obd2AdapterProfile(
    id: 'kiwi-3',
    displayName: 'PLX Kiwi 3',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['kiwi'],
  ),
  // LELink / LELink2 — popular low-cost BLE ELM327 clone, common on
  // Amazon and iOS-friendly (#1641). Nordic-UART FFF0 family.
  Obd2AdapterProfile(
    id: 'lelink',
    displayName: 'LELink BLE',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['lelink'],
  ),
  // Topdon TopScan — recent best-selling BLE OBD2 adapter (#1641).
  // Advertises as "TopScan" / "Topdon".
  Obd2AdapterProfile(
    id: 'topdon-topscan',
    displayName: 'Topdon TopScan',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['topscan', 'topdon'],
  ),
  // ANCEL BD310 — dual-mode (app + standalone display) BLE adapter,
  // a steady Amazon best-seller (#1641). Nordic-UART FFF0 family.
  Obd2AdapterProfile(
    id: 'ancel-bd310',
    displayName: 'ANCEL BD310',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['ancel', 'bd310'],
  ),
  // Tonwon Pro — widely-sold low-cost BLE ELM327 clone (#1641).
  Obd2AdapterProfile(
    id: 'tonwon',
    displayName: 'Tonwon Pro BLE',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['tonwon'],
  ),
  // NEXAS NexLink — popular BLE OBD2 adapter sold across Amazon EU
  // (#1641). Nordic-UART FFF0 family.
  Obd2AdapterProfile(
    id: 'nexas-nexlink',
    displayName: 'NEXAS NexLink',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['nexas', 'nexlink'],
  ),
  // Generic ELM327 BLE fallback. Matches any clone that advertises
  // the FFF0 service but has an unfamiliar name (plenty on Amazon).
  // No nameMatchers — reached only via service-UUID pass.
  Obd2AdapterProfile(
    id: 'generic-fff0',
    displayName: 'Generic ELM327 (BLE)',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
  ),
  // Generic ELM327 BLE fallback by NAME (#3097). A clone that advertises a
  // generic name (`OBDII`, `ELM327 v1.5`, …) but NO service UUID — the iOS
  // case: CoreBluetooth surfaces it by name only. Listed BEFORE the
  // generic-classic entry so a BLE-discovered generic name resolves to a BLE
  // profile (resolve() prefers the discovery transport for this BLE+Classic
  // name pair). NO pinned service UUID — the channel's dynamic GATT discovery
  // (#3014, see elm_gatt_profiles.dart) finds the ELM service post-connect
  // among FFE0/FFF0/18F0/Nordic-UART by characteristic property, so a
  // name-only adapter still connects.
  Obd2AdapterProfile(
    id: 'generic-ble',
    displayName: 'Generic ELM327 (BLE)',
    nameMatchers: _genericElmNameMatchers,
  ),
  // Generic ELM327 Classic SPP fallback (#761). Matches any bonded
  // device whose name contains "obd" or "elm327" — the common ones
  // on Amazon / AliExpress that predate BLE. Classic can't be
  // discovered by service-UUID (SPP is 0x1101 universally); the
  // name signature is all we have.
  Obd2AdapterProfile(
    id: 'generic-classic',
    displayName: 'Generic ELM327 (Classic)',
    transport: BluetoothTransport.classic,
    nameMatchers: _genericElmNameMatchers,
  ),
];

/// Shared generic-ELM327 name signature used by BOTH the `generic-ble` and
/// `generic-classic` fallback profiles (#3097). One source of truth so the two
/// transports always match the same set of names; [Obd2AdapterRegistry.resolve]
/// disambiguates which transport a given hit lands on via its discovery
/// transport.
const List<String> _genericElmNameMatchers = [
  'obdii',
  'obd-ii',
  'obd ii',
  'obd2',
  'elm327',
];

/// Re-export so callers can still reach the protocol types via the
/// registry module without having to cross-import.
// ignore: unused_element
typedef _ReExport = Elm327Protocol;
