// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3014 (Epic #3013, Phase 2) — property-based ELM327 GATT service/characteristic
/// discovery, extracted as a PURE, platform-free module so it is unit-tested
/// without a flutter_blue_plus stack.
///
/// ## Why this exists
/// The pre-#3014 discovery hard-pinned FFF0/FFF2/FFF1 with an exact-UUID
/// `firstWhere`-or-throw. An HM-10-class clone (the maintainer's SmartOBD)
/// exposes the FFE0 service with a SINGLE dual-mode characteristic FFE1
/// (write AND notify on one char), or other clones expose 18F0 / Nordic-UART
/// (6E40…). Any of these threw a `StateError` on discovery → the BLE adapter
/// never connected.
///
/// ## The fix (van Welie / Punch Through / crickshaw.dev BLE references)
/// Match by characteristic PROPERTY, not by exact UUID:
///   * writeChar  = first char advertising `write` OR `writeWithoutResponse`;
///   * notifyChar = first char advertising `notify` OR `indicate`.
/// The HM-10 single-dual-char case (one char that is both writable and
/// notifiable, e.g. FFE1) resolves write == notify — which is correct for that
/// hardware. The registry UUIDs stay a FIRST-PRIORITY hint (try the known
/// service + exact write/notify first), then fall to property matching across
/// the candidate ELM families, then to ANY service exposing a writable + a
/// notifiable characteristic.

library;

/// One discovered BLE characteristic, reduced to the four GATT properties that
/// matter for an ELM327 byte pipe. Platform-free so the matcher is pure; the
/// channel adapts a real `BluetoothCharacteristic` into this at the edge.
class GattCharDescriptor {
  /// Lower-cased, dash-normalised 128-bit characteristic UUID.
  final String uuid;
  final bool write;
  final bool writeWithoutResponse;
  final bool notify;
  final bool indicate;

  const GattCharDescriptor({
    required this.uuid,
    this.write = false,
    this.writeWithoutResponse = false,
    this.notify = false,
    this.indicate = false,
  });

  /// Can this characteristic carry ELM commands TO the adapter?
  bool get isWritable => write || writeWithoutResponse;

  /// Can this characteristic deliver ELM replies FROM the adapter?
  bool get isNotifiable => notify || indicate;
}

/// One discovered BLE service + its characteristics.
class GattServiceDescriptor {
  /// Lower-cased, dash-normalised 128-bit service UUID.
  final String uuid;
  final List<GattCharDescriptor> characteristics;

  const GattServiceDescriptor({
    required this.uuid,
    required this.characteristics,
  });
}

/// The resolved write + notify characteristic pair on a matched service, plus
/// the service they live on. For the HM-10 single-dual-char case
/// [writeCharUuid] == [notifyCharUuid].
class ResolvedElmGatt {
  final String serviceUuid;
  final String writeCharUuid;
  final String notifyCharUuid;

  /// How the pair was resolved — for the trace timeline + maintainer triage.
  /// `'hint-exact'` (registry UUIDs matched exactly), `'family-property'` (a
  /// known ELM family matched by characteristic property), or
  /// `'any-property'` (the last-resort any-writable+notifiable service).
  final String matchReason;

  const ResolvedElmGatt({
    required this.serviceUuid,
    required this.writeCharUuid,
    required this.notifyCharUuid,
    required this.matchReason,
  });
}

/// The 16-bit ELM327 BLE service families, expanded to full 128-bit Bluetooth
/// base UUIDs. Lower-cased so a case-insensitive compare against the discovered
/// services is a plain `==`. Order is the search priority.
///
///   * FFF0 — Nordic-UART variant, the dominant ELM327 clone (vLinker FD/MC,
///     Veepeak, Carista, Vgate, BlueDriver, …).
///   * FFE0 — HM-10 / CC254x module family (SmartOBD + many cheap clones),
///     usually a single dual-mode FFE1 char.
///   * 18F0 — Scantool STN (OBDLink MX+/LX/CX).
///   * 6E40… — the canonical Nordic UART Service (some firmware exposes it).
const List<String> kElmBleServiceFamilies = [
  '0000fff0-0000-1000-8000-00805f9b34fb',
  '0000ffe0-0000-1000-8000-00805f9b34fb',
  '000018f0-0000-1000-8000-00805f9b34fb',
  '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
];

/// Normalise a UUID for comparison: trimmed + lower-cased. (The channel already
/// hands full 128-bit dash-form UUIDs from `Guid.str`, so no widening is needed
/// here — this just guards against case/whitespace drift.)
String normalizeGattUuid(String uuid) => uuid.trim().toLowerCase();

/// Resolve the ELM327 write + notify characteristic pair from the [services]
/// discovered on a BLE device (#3014). Returns null when no service exposes a
/// usable writable + notifiable pair — the caller then stamps `serviceNotFound`
/// and logs the discovered layout for the maintainer.
///
/// Resolution order (first hit wins):
///   1. **Hint-exact** — if [hintServiceUuid] is present in the discovered set
///      AND it carries the exact [hintWriteCharUuid] + [hintNotifyCharUuid],
///      use them. This preserves the known-good fast path for every registry
///      profile (and keeps quirks like the OBDLink 18F0/2af0/2af1 pair exact).
///   2. **Family-property** — for each known ELM family (in
///      [kElmBleServiceFamilies] order) present in the discovered set, pick
///      writeChar = first writable char, notifyChar = first notifiable char.
///      Handles the HM-10 single-dual-char case (write == notify).
///   3. **Any-property** — last resort: the FIRST discovered service (in
///      discovery order) that exposes a writable char AND a notifiable char.
///
/// Pure + total: never throws.
ResolvedElmGatt? resolveElmGatt(
  List<GattServiceDescriptor> services, {
  String? hintServiceUuid,
  String? hintWriteCharUuid,
  String? hintNotifyCharUuid,
}) {
  if (services.isEmpty) return null;

  // 1) Hint-exact — the known-good fast path. Only when ALL THREE hint UUIDs
  //    are present and the chars actually exist on the hinted service.
  if (hintServiceUuid != null &&
      hintWriteCharUuid != null &&
      hintNotifyCharUuid != null) {
    final hs = normalizeGattUuid(hintServiceUuid);
    final hw = normalizeGattUuid(hintWriteCharUuid);
    final hn = normalizeGattUuid(hintNotifyCharUuid);
    for (final s in services) {
      if (normalizeGattUuid(s.uuid) != hs) continue;
      final hasWrite =
          s.characteristics.any((c) => normalizeGattUuid(c.uuid) == hw);
      final hasNotify =
          s.characteristics.any((c) => normalizeGattUuid(c.uuid) == hn);
      if (hasWrite && hasNotify) {
        return ResolvedElmGatt(
          serviceUuid: s.uuid,
          writeCharUuid: hw,
          notifyCharUuid: hn,
          matchReason: 'hint-exact',
        );
      }
    }
  }

  // 2) Family-property — a known ELM family matched by characteristic property.
  for (final family in kElmBleServiceFamilies) {
    for (final s in services) {
      if (normalizeGattUuid(s.uuid) != family) continue;
      final resolved = _byProperty(s, 'family-property');
      if (resolved != null) return resolved;
    }
  }

  // 3) Any-property — last resort: any service with a writable + notifiable pair.
  for (final s in services) {
    final resolved = _byProperty(s, 'any-property');
    if (resolved != null) return resolved;
  }

  return null;
}

/// Pick writeChar = first writable char, notifyChar = first notifiable char on
/// [s]. Returns null when either role is absent (so the caller keeps searching).
/// The HM-10 single-dual-char case resolves write == notify naturally.
ResolvedElmGatt? _byProperty(GattServiceDescriptor s, String reason) {
  GattCharDescriptor? writeChar;
  GattCharDescriptor? notifyChar;
  for (final c in s.characteristics) {
    if (writeChar == null && c.isWritable) writeChar = c;
    if (notifyChar == null && c.isNotifiable) notifyChar = c;
  }
  if (writeChar == null || notifyChar == null) return null;
  return ResolvedElmGatt(
    serviceUuid: s.uuid,
    writeCharUuid: normalizeGattUuid(writeChar.uuid),
    notifyCharUuid: normalizeGattUuid(notifyChar.uuid),
    matchReason: reason,
  );
}

/// A compact, one-line dump of the discovered GATT layout for the FAILED-open
/// trace (#3014): `svc fff0[w:fff2,n:fff1]; svc 180a[...]`. Lets the maintainer
/// confirm a clone's real service/char/property layout from the next capture
/// without a USB debugger. Caps the output so a pathological device can't
/// blow the trace's per-step detail.
String describeGattLayout(List<GattServiceDescriptor> services) {
  if (services.isEmpty) return '(no services discovered)';
  final buf = StringBuffer();
  var serviceCount = 0;
  for (final s in services) {
    if (serviceCount++ >= 12) {
      buf.write('; …');
      break;
    }
    if (buf.isNotEmpty) buf.write('; ');
    buf.write('svc ${_short(s.uuid)}[');
    var charCount = 0;
    for (final c in s.characteristics) {
      if (charCount++ >= 8) {
        buf.write(',…');
        break;
      }
      if (charCount > 1) buf.write(',');
      buf.write('${_short(c.uuid)}:${_props(c)}');
    }
    buf.write(']');
  }
  return buf.toString();
}

/// The 16-bit short form when a UUID is on the Bluetooth base, else the full
/// UUID — keeps the layout dump readable for the common 16-bit clones.
String _short(String uuid) {
  final u = normalizeGattUuid(uuid);
  if (u.length == 36 &&
      u.startsWith('0000') &&
      u.endsWith('-0000-1000-8000-00805f9b34fb')) {
    return u.substring(4, 8);
  }
  return u;
}

/// Compact property flags: w=write, W=writeNoResp, n=notify, i=indicate.
String _props(GattCharDescriptor c) {
  final b = StringBuffer();
  if (c.write) b.write('w');
  if (c.writeWithoutResponse) b.write('W');
  if (c.notify) b.write('n');
  if (c.indicate) b.write('i');
  return b.isEmpty ? '-' : b.toString();
}
