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

/// One supported ELM327-compatible BLE adapter. Selected by the
/// registry based on name substring + advertised service UUIDs.
class Obd2AdapterProfile {
  /// Stable internal id, used when persisting the last-connected
  /// adapter to Hive (`vlinker-fs`, `obdlink-mx`, `generic-fff0`, …).
  final String id;

  /// Marketing name shown in the picker.
  final String displayName;

  /// BLE service/characteristic UUIDs this adapter exposes. The
  /// connection service feeds these to `FlutterBluePlusElmChannel`.
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
  final Duration initDelay;

  /// Extra AT commands appended after the shared init sequence
  /// (e.g. `ATSP6\r` to pin ISO 15765-4 on Volvos; `ATST FF\r` for
  /// slow cars that miss the default 200 ms timeout).
  final List<String> extraInitCommands;

  const Obd2AdapterProfile({
    required this.id,
    required this.displayName,
    required this.serviceUuid,
    required this.writeCharUuid,
    required this.notifyCharUuid,
    this.nameMatchers = const [],
    this.initDelay = const Duration(milliseconds: 100),
    this.extraInitCommands = const [],
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

  /// All service UUIDs the registry knows about. Handed to
  /// `FlutterBluePlus.startScan(withServices: ...)` so the scan
  /// filters out consumer BLE noise (fitness trackers, headphones).
  Set<String> get allServiceUuids =>
      profiles.map((p) => p.serviceUuid.toLowerCase()).toSet();

  /// Pick the best profile for [candidate]. Returns null when the
  /// candidate is clearly not an OBD2 adapter.
  Obd2AdapterProfile? resolve(Obd2AdapterCandidate candidate) {
    // Pass 1: named match. A named profile wins over a generic one
    // if the advertised name carries its signature.
    for (final p in profiles) {
      if (p.matchesName(candidate.deviceName)) return p;
    }
    // Pass 2: service UUID match, but only against generic/nameless
    // profiles. Named profiles (vLinker, OBDLink, Carista…) require
    // their name to be seen — otherwise a random clone advertising the
    // FFF0 service would be mis-labelled as "vLinker" just because
    // it's the first FFF0 profile in the list.
    for (final p in profiles) {
      if (p.nameMatchers.isNotEmpty) continue;
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
  // vLinker FS / FD / MC — the target adapter for #733. Nordic UART
  // variant: FFF0 service, FFF2 write, FFF1 notify. Name advertises
  // as "vLinker FS" or similar; some firmware reports "VLink".
  Obd2AdapterProfile(
    id: 'vlinker',
    displayName: 'vLinker FS / FD / MC',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
    nameMatchers: ['vlinker', 'vlink', 'vgate'],
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
];

/// Re-export so callers can still reach the protocol types via the
/// registry module without having to cross-import.
// ignore: unused_element
typedef _ReExport = Elm327Protocol;
