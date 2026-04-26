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

## Supported adapters

| Display name | Transport | Name matchers | Notes |
|---|---|---|---|
| vLinker FS (Classic) | Classic BT | `vlinker fs`, `vlinker ms`, `vlink fs`, `vgate fs` | Dominant Amazon-EU model; Classic SPP |
| vLinker FD / MC (BLE) | BLE | `vlinker fd`, `vlinker mc`, `vlink fd`, `vlink mc` | Nordic UART FFF0 family |
| OBDLink MX+ | BLE | `obdlink` | Scantool premium adapter; custom 18f0 service |
| Carista OBD2 | BLE | `carista` | Nordic UART FFF0 family |
| Veepeak BLE+ | BLE | `veepeak` | Nordic UART FFF0 family |
| SmartOBD (BLE) | BLE | `smartobd` | Generic ELM327 v1.5 clone |
| SmartOBD (Classic) | Classic BT | `smartobd` | Same brand, Classic SPP variant |
| ieGeek Scanner | BLE | `iegeek` | ELM327 v2.1 BLE clone |
| vLinker BM+ (BLE) | BLE | `vlinker bm+`, `vlink bm+` | BLE-only sibling to vLinker BM; the "+" is load-bearing |
| Konnwei KW902 | Classic BT | `konnwei`, `kw902` | ELM327 v1.5 Classic clone |
| Vgate iCar Pro | BLE | `vgate`, `icar pro` | Chinese brand; BLE variant (WiFi variant handled by TCP facade) |
| Panlong WiFi | Classic BT (no-op) | `panlong` | WiFi-only adapter; name kept so the UI can label a mis-paired Classic entry |
| BAFX 34t5 | Classic BT | `bafx` | Legacy ELM327 v1.5 adapter, still sold in the US |
| Generic ELM327 (BLE) | BLE | — (matched by FFF0 service UUID) | Catch-all for unfamiliar BLE FFF0 clones |
| Generic ELM327 (Classic) | Classic BT | `obdii`, `obd-ii`, `obd ii`, `obd2`, `elm327` | Catch-all for unfamiliar Classic-SPP clones |

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
