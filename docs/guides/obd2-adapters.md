# Supported OBD2 Adapters

This is the list of OBD2 adapter models Tankstellen recognises by
Bluetooth advertisement name. If your adapter is not in the table,
it falls through to the generic ELM327 profile — most of the time
that still works; add your model here if you have a name-matching
rule that improves the experience (for example a confident
"this is brand X" label in the picker, or a longer init delay
for a chip that misses the default timing).

The registry source of truth is
`lib/features/consumption/data/obd2/adapter_registry.dart`; the
catalogue below is curated manually from that file.

## Buying an adapter (#1648 decisions)

The table carries a **Buy** column with a link per adapter. The
sourcing decisions, recorded here so they don't drift:

- **Plain links, no affiliate program.** The links are ordinary
  Amazon *search* URLs — not affiliate / tag links — so there is no
  affiliate-disclosure obligation and no account to maintain.
- **Search URLs, not product ASINs.** Each link is an Amazon search
  for the adapter name (`amazon.de/s?k=<name>+OBD2`). Search URLs are
  stable; a specific product listing's ASIN rots when the seller
  re-lists, a search does not.
- **Reference marketplace: amazon.de.** It is the app's home market.
  The search-by-name query works unchanged on any Amazon marketplace
  (swap the TLD) and on any other retailer — so countries Amazon does
  not serve are covered by the same adapter *name*.
- **Doc-only, not in-app.** The links live in this guide (and the
  wiki it feeds), not in an in-app registry field — the adapter
  picker stays a connection tool, not a storefront.

## Compatibility status

Each adapter row carries one of three states, sourced from the
`Obd2AdapterCompatibility` enum in
`lib/features/consumption/data/obd2/adapter_registry.dart`:

- ✅ **tested** — the maintainer has confirmed connect + live PID
  stream on real hardware.
- 👤 **user-verified** — at least one user reported it working in a
  GitHub issue (cite the issue number in the row's Notes column when
  helpful).
- ⚠️ **theoretical** — name-matched profile only; adapter has not
  been verified end-to-end by anyone. Should still work because the
  GATT profile / SPP transport is correct, but if you have one and
  it works (or doesn't), please open an issue so we can promote it.

## Platform support — iOS vs Android (#1542 phase 8)

**iOS supports BLE adapters only.** The `Transport` column in the
table below distinguishes `BLE` from `Classic BT`:

- **BLE** adapters work on **both Android and iOS**.
- **Classic BT** (Bluetooth SPP) adapters work on **Android only**.

This is an Apple platform constraint, not a project limitation. iOS
does not let a third-party app open a Classic-Bluetooth SPP
connection to an arbitrary device — the accessory must be
MFi-certified and the app must talk to it through the External
Accessory framework under Apple's Made-for-iPhone programme. ELM327
Classic-BT adapters (vLinker FS, the BM-Android variant, BAFX,
Konnwei, the generic SPP clones) are not MFi-certified, so **no
amount of app-side work can reach them on iOS** — an External
Accessory path is not buildable for these adapters.

**Decision (#1542 phase 8):** iOS ships BLE-only adapter support;
no External Accessory / classic-BT path is added. `flutter_blue_plus`
on iOS surfaces only BLE peripherals, so the in-app adapter picker
already shows the right subset with no platform branch. iOS users
should buy a **BLE** adapter — e.g. vLinker FD/MC, OBDLink
MX+/LX/CX, Veepeak BLE+, or any generic FFF0 ELM327 BLE clone.

## Supported adapters

| Display name | Transport | Name matchers | Compatibility | Buy |
|---|---|---|---|---|
| vLinker FS (Classic) | Classic BT | `vlinker fs`, `vlinker ms`, `vlink fs`, `vgate fs` | ✅ tested | [amazon.de](https://www.amazon.de/s?k=vLinker+FS+OBD2) |
| vLinker FD / MC (BLE) | BLE | `vlinker fd`, `vlinker mc`, `vlink fd`, `vlink mc` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=vLinker+FD+OBD2) |
| vLinker BM+ (BLE) | BLE | `vlinker bm+`, `vlink bm+` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=vLinker+BM+OBD2) |
| vLinker BM-Android (Classic) | Classic BT | `vlinker bm-android`, `vlink bm-android` | ✅ tested | [amazon.de](https://www.amazon.de/s?k=vLinker+BM+OBD2) |
| OBDLink MX+ | BLE | `obdlink mx` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=OBDLink+MX+) |
| OBDLink LX | BLE | `obdlink lx` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=OBDLink+LX) |
| OBDLink CX | BLE | `obdlink cx` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=OBDLink+CX) |
| Carista OBD2 | BLE | `carista` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=Carista+OBD2) |
| Veepeak BLE+ | BLE | `veepeak` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=Veepeak+OBD2) |
| BlueDriver | BLE | `bluedriver` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=BlueDriver+OBD2) |
| PLX Kiwi 3 | BLE | `kiwi` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=PLX+Kiwi+3+OBD2) |
| SmartOBD (BLE) | BLE | `smartobd` | 👤 user-verified | [amazon.de](https://www.amazon.de/s?k=SmartOBD+ELM327) |
| SmartOBD (Classic) | Classic BT | `smartobd` | 👤 user-verified | [amazon.de](https://www.amazon.de/s?k=SmartOBD+ELM327) |
| ieGeek Scanner | BLE | `iegeek` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=ieGeek+OBD2) |
| LELink BLE | BLE | `lelink` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=LELink+OBD2) |
| Topdon TopScan | BLE | `topscan`, `topdon` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=Topdon+TopScan) |
| ANCEL BD310 | BLE | `ancel`, `bd310` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=ANCEL+BD310) |
| Tonwon Pro BLE | BLE | `tonwon` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=Tonwon+Pro+OBD2) |
| NEXAS NexLink | BLE | `nexas`, `nexlink` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=NEXAS+NexLink+OBD2) |
| Konnwei KW902 | Classic BT | `konnwei`, `kw902` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=Konnwei+KW902) |
| Vgate iCar Pro | BLE | `vgate`, `icar pro` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=Vgate+iCar+Pro) |
| BAFX 34t5 | Classic BT | `bafx` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=BAFX+OBD2) |
| Panlong WiFi | Classic BT (no-op) | `panlong` | ⚠️ theoretical | [amazon.de](https://www.amazon.de/s?k=Panlong+WiFi+OBD2) |
| Generic ELM327 (BLE) | BLE | — (matched by FFF0 service UUID) | ⚠️ theoretical | — |
| Generic ELM327 (Classic) | Classic BT | `obdii`, `obd-ii`, `obd ii`, `obd2`, `elm327` | ⚠️ theoretical | — |

The Notes for each profile (chip family, transport quirks) live in
the `adapter_registry.dart` source comments — the doc keeps the table
scannable; the registry file is the long-form reference.

## How to add a new adapter

1. Open `lib/features/consumption/data/obd2/adapter_registry.dart`.
2. Add a new `Obd2AdapterProfile(...)` entry in the `_defaultProfiles`
   const list. Place it **before** the two generic fallbacks
   (`generic-fff0`, `generic-classic`) — the generics must remain the
   last two entries so unfamiliar devices still resolve to a
   catch-all.
3. Populate at minimum:
   - `id` — stable internal id (`kebab-case`).
   - `displayName` — marketing name shown in the picker.
   - `transport` — `BluetoothTransport.ble` (default) or
     `BluetoothTransport.classic`.
   - `nameMatchers` — case-insensitive substrings the advertisement
     name is matched against.
4. If the adapter is BLE and uses a known GATT profile, also set
   `serviceUuid`, `writeCharUuid`, `notifyCharUuid`. The Nordic UART
   family is `0000fff0-…` / `0000fff2-…` / `0000fff1-…`.
5. Add a name-match test to
   `test/features/consumption/data/obd2/adapter_registry_test.dart`
   that asserts `resolve(_candidate(name: '<brand-string>', …))`
   returns your new profile id. Follow the pattern of the
   `#949` block at the bottom of the file.
6. Update the table in this document (`docs/guides/obd2-adapters.md`).
7. Run `flutter analyze` and `flutter test` before sending the PR.

## Upstream limitation: odometer reading (PID 0xA6)

`Obd2Service.readOdometerKm()` uses the standard OBD-II Mode 01 PID 0xA6
("odometer") with a brand-specific fallback list. On real hardware this
PID is **not honoured by every ECU + adapter combination**:

- **Generic ELM327 BLE clones** (most of the registry above) frequently
  return `NO DATA` or `?` for PID 0xA6 even on vehicles whose ECU
  stores a total-kilometre counter. The PID was added to the standard
  in 2014 — pre-2014 ECUs simply do not implement it.
- **PSA / Stellantis vehicles** (Peugeot, Citroën, DS, Opel) expose the
  odometer over **UDS service `$22` data identifier `$D110`**, not the
  standard $01 $A6 path. Reading it requires switching the protocol
  with `AT SP 6` (ISO 15765-4 CAN 11/500) and issuing a service-22
  request, which the current implementation does not do.
- Confirmed user report (#951): Galaxy S23 + a generic ELM327 BLE
  adapter against a Peugeot 107 returns null on every retry, so the
  fill-up form's "OBD-II adapter" import tile defeats its own purpose
  (the user still has to type the odometer manually).

Because of this, **the OBD-II import tile was removed from
`AddFillUpScreen` in #951** until the implementation gains a
brand-specific UDS path for at least the PSA family. The full OBD-II
trajet flow on the Consumption screen is unaffected — it relies on
live PID 0x0F (engine RPM) and PID 0x10 (mass air flow) for fuel-rate
estimation, not on the odometer counter.

If you implement a brand-specific odometer reader (UDS $22 $D110 for
PSA, $22 $F40D for VAG, etc.) and verify it on the brand's hardware,
flip the fill-up screen back to a 3-option import affordance — the
prior chip + bottom-sheet pattern is preserved in the git history at
commit before #951's revert.

## Reference

- Registry source: `lib/features/consumption/data/obd2/adapter_registry.dart`
- Tests: `test/features/consumption/data/obd2/adapter_registry_test.dart`
- Related issues: #733 (initial registry), #761 (Classic transport),
  #949 (expansion), #951 (odometer-unreliable rollback).
