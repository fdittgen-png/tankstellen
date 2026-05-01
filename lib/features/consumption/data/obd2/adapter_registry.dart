import 'elm327_adapter.dart';
import 'elm327_protocol.dart';

/// Thin value-object describing one BLE scan result. Kept
/// flutter_blue_plus-free so the registry can be unit-tested without
/// the platform plugin (the real connection service converts
/// `ScanResult` into this shape at the edge). Step 1 of #733.
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

  Obd2AdapterCandidate({
    required this.deviceId,
    required this.deviceName,
    required Iterable<String> advertisedServiceUuids,
    required this.rssi,
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

  /// Some clones need a few hundred ms between consecutive ELM
  /// init commands — otherwise the chip drops bytes. Default is
  /// 100 ms (what [Obd2Service.connect] already does).
  ///
  /// Deprecated in #1330 phase 1 — use [adapter.postResetDelay] /
  /// [adapter.interCommandDelay] instead. Field stays in place so
  /// the few historical call sites still compile; will be removed
  /// in phase 2 once every caller routes through [adapter].
  @Deprecated('Use adapter.postResetDelay / adapter.interCommandDelay')
  final Duration initDelay;

  /// Extra AT commands appended after the shared init sequence
  /// (e.g. `ATSP6\r` to pin ISO 15765-4 on Volvos; `ATST FF\r` for
  /// slow cars that miss the default 200 ms timeout).
  ///
  /// Deprecated in #1330 phase 1 — use [adapter.extraInitCommands]
  /// instead. Removed in phase 2.
  @Deprecated('Use adapter.extraInitCommands')
  final List<String> extraInitCommands;

  /// Per-adapter ELM327 protocol quirks (#1330): init sequence,
  /// timing, response pre-parse hook. Phase 1 ships only the
  /// [GenericElm327Adapter] default — runtime behaviour is identical
  /// for every profile until phases 2/3 introduce specialised
  /// adapters.
  final Elm327Adapter adapter;

  const Obd2AdapterProfile({
    required this.id,
    required this.displayName,
    this.transport = BluetoothTransport.ble,
    this.serviceUuid = '',
    this.writeCharUuid = '',
    this.notifyCharUuid = '',
    this.nameMatchers = const [],
    this.initDelay = const Duration(milliseconds: 100),
    this.extraInitCommands = const [],
    this.adapter = const GenericElm327Adapter(),
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

  /// All BLE service UUIDs the registry knows about. Handed to
  /// `FlutterBluePlus.startScan(withServices: ...)` so the scan
  /// filters out consumer BLE noise (fitness trackers, headphones).
  /// Classic profiles are excluded — SPP uses a single universal
  /// UUID and Classic discovery doesn't filter by service anyway.
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
    for (final p in profiles) {
      if (p.matchesName(candidate.deviceName)) return p;
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
  // OBDLink MX+ — Scantool's premium adapter, uses a custom service
  // UUID pair. Name always starts with "OBDLink".
  Obd2AdapterProfile(
    id: 'obdlink-mx',
    displayName: 'OBDLink MX+',
    serviceUuid: '000018f0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '00002af1-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '00002af0-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['obdlink'],
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
  ),
  Obd2AdapterProfile(
    id: 'smartobd-classic',
    displayName: 'SmartOBD (Classic)',
    transport: BluetoothTransport.classic,
    nameMatchers: ['smartobd'],
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
  // Generic ELM327 BLE fallback. Matches any clone that advertises
  // the FFF0 service but has an unfamiliar name (plenty on Amazon).
  // No nameMatchers — reached only via service-UUID pass.
  Obd2AdapterProfile(
    id: 'generic-fff0',
    displayName: 'Generic ELM327 (BLE)',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    initDelay: Duration(milliseconds: 300),
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
    nameMatchers: ['obdii', 'obd-ii', 'obd ii', 'obd2', 'elm327'],
    initDelay: Duration(milliseconds: 300),
  ),
];

/// Re-export so callers can still reach the protocol types via the
/// registry module without having to cross-import.
// ignore: unused_element
typedef _ReExport = Elm327Protocol;
