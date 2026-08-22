// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'adapter_registry.dart';

/// Default adapter-profile catalog for [Obd2AdapterRegistry], extracted
/// from `adapter_registry.dart` as a `part` so the catalog data keeps
/// library-level private access while the registry file stays under the
/// #1680 file-length cap (sanctioned #3760 decomposition — move-only,
/// behaviour preserved).

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
  // #3180 — the CX does NOT use the MX+/LX 18F0/2AF1/2AF0 layout it was
  // originally pinned to: the vendor-documented CX GATT profile is service
  // FFF0 with notify FFF1 / write FFF2 (the Nordic-UART-style family). The
  // wrong hint made the exact-UUID first-priority match miss on every CX.
  Obd2AdapterProfile(
    id: 'obdlink-cx',
    displayName: 'OBDLink CX',
    serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
    writeCharUuid: '0000fff2-0000-1000-8000-00805f9b34fb',
    notifyCharUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
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
  // #3103 — broadened from the exact `obdii/obd2/elm327` set to the bare `obd`
  // / `elm` stems so common clone names (`Kiwi OBD`, `Vgate OBD`, `ELM 327`,
  // `OBD Mini`) resolve to a real generic profile + transport instead of
  // landing in the picker's "unrecognized" bucket. A rare false positive (a
  // non-OBD device whose name contains `obd`/`elm`) only earns a recognized
  // row whose connect then fails — strictly better than HIDING a real adapter;
  // anything still unmatched is surfaced by the two-section picker (#3103).
  'obd',
  'elm',
];

/// #3103 — synthetic profiles the registry attaches to a NAMED device it does
/// NOT recognize, so [Obd2AdapterRegistry.rank] can CLASSIFY (not drop) it and
/// the picker can offer it under "other devices — tap to try". Transport is the
/// device's DISCOVERY transport so a connect routes over the right facade
/// (BLE → dynamic GATT like `generic-ble`; bonded Classic → RFCOMM).
/// `displayName` is empty — never shown; the picker renders the device's own
/// advertised name for an unrecognized entry. `id: 'unrecognized'` is never
/// persisted as a known profile (reconnect re-resolves by MAC + name).
const Obd2AdapterProfile _unrecognizedBleProfile = Obd2AdapterProfile(
  id: 'unrecognized',
  displayName: '',
);
const Obd2AdapterProfile _unrecognizedClassicProfile = Obd2AdapterProfile(
  id: 'unrecognized',
  displayName: '',
  transport: BluetoothTransport.classic,
);
