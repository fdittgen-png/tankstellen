// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#1680 / #2351): no *new* handwritten Dart file in
/// `lib/` may exceed [_lineLimit] lines, and no *grandfathered* file may
/// **grow** beyond its snapshot line count.
///
/// ### Cap for new files
/// The ~400-line norm keeps files reviewable and decomposable. Any file
/// not in [_grandfatheredSnapshot] that exceeds the cap fails CI.
///
/// ### One-way ratchet for grandfathered files (#2351)
/// Each grandfathered file was measured when it entered the set; that
/// count is recorded in [_grandfatheredSnapshot]. The test enforces two
/// invariants:
///
/// 1. **Shrink signal** — if a grandfathered file has been decomposed
///    below the cap, the entry must be removed (stale-baseline check).
/// 2. **Growth block** — if a grandfathered file's current line count
///    *exceeds* its snapshot, CI fails immediately. This prevents
///    balloon growth across PRs with no incremental signal.
///
/// When a file legitimately needs more lines during a refactoring, the
/// snapshot entry must be updated in the same PR, with a comment
/// explaining why — and the entry's `bumps` counter incremented.
///
/// ### Anti-re-grandfathering ratchet (#3141)
/// Repeated "justified +N" re-grandfatherings are how god files grow
/// forever (app_initializer took 9 bumps in one iteration; ~40 upward
/// bumps are recorded in this file's own comments). Each snapshot entry
/// therefore carries a `bumps` counter — the number of UPWARD snapshot
/// changes since the entry was created (shrinks don't count). Once a
/// file accumulates **3 or more bumps**, its entry MUST reference an
/// **open** GitHub decomposition issue via `decompositionIssue`, or the
/// test fails. The issue must stay open until the file graduates below
/// the cap; closing it without decomposing means the next bump fails
/// review honesty, not just CI. Existing entries were seeded at their
/// historical bump counts (parsed from the re-grandfather comments) and
/// linked to the open decomposition issues of epic #3136.
///
/// Generated files are not scanned: `.g.dart` / `.freezed.dart` and the
/// `lib/l10n/app_localizations*.dart` outputs of `flutter gen-l10n`
/// (each thousands of lines, none handwritten).

/// One grandfathered file's ratchet state (#1680 / #2351 / #3141):
/// the snapshot [lines] count, the upward re-grandfathering [bumps]
/// counter, and the open [decompositionIssue] number (mandatory once
/// `bumps >= 3`).
typedef _GrandfatherEntry = ({int lines, int bumps, int? decompositionIssue});

void main() {
  const lineLimit = 400;

  // A file may be re-grandfathered upward at most this many times before
  // an OPEN decomposition issue must be referenced in its entry (#3141).
  const reGrandfatherBumpLimit = 3;

  // Snapshot map: grandfathered path → ratchet state.
  //  - lines: line count at (re-)grandfathering time (SPDX header
  //    excluded, same as the runtime count). The growth ratchet fails
  //    CI if current > lines.
  //  - bumps: UPWARD snapshot changes since the entry was created.
  //    When you raise `lines` you MUST increment `bumps` by 1 in the
  //    same edit (a shrink or a removal never increments).
  //  - decompositionIssue: the OPEN GitHub issue tracking this file's
  //    decomposition — MANDATORY once bumps >= 3 (#3141).
  // Update an entry only for a legitimate re-grandfathering (same PR,
  // with a comment). NEVER add new entries — use decomposition instead.
  const grandfatheredSnapshot = <String, _GrandfatherEntry>{
    // #2465 — re-grandfathered 934 → 950: a post-first-frame warm-up block
    // that reads `obd2CommDiagnosticsGateProvider` to arm the gated OBD2
    // comm-health collector from `Feature.debugMode` (mirrors the adjacent
    // #1925 `obd2DebugSessionLoggingProvider` kick-off).
    // #2597 — re-grandfathered 950 → 957: the post-first-frame migration
    // block now also runs `ProfileRepository.dedupeCountryProfiles()` to
    // enforce one profile per country for existing duplicate users (a few
    // lines next to the adjacent country/language backfill migration).
    // #2772 — 957 → 961: the isBenignStreamCancel de-noise helper + its
    // services import + the two global-handler filter calls. Bootstrap file.
    // #2978 — 961 → 964: `initializeDateFormatting()` + its import + comment,
    // so `intl` locale date-symbols are loaded once at startup and the
    // localized price-prediction weekday renders for non-`en_US` locales.
    // #3077 — re-grandfathered 964 → 1028: the launch-time
    // `_runEntitySyncMerge` (+ its post-`_runTripsSyncMerge` call site +
    // 5 provider imports) pulls the remaining server→local entities
    // (ratings/alerts/fill-ups/vehicles) on cold start, mirroring the
    // adjacent trips merge. The unit-tested logic lives in the per-entity
    // provider seams; this is the (compacted) launch glue. Decomposition
    // of this god-file is tracked separately.
    // #3143 — re-grandfathered 1028 → 1046: ~20 release-silent
    // debugPrint-only catch handlers converted to `errorLogger.log(...)`
    // with a `where` context map (each conversion is +1 line); enforced
    // at 0 by test/lint/no_debugprint_only_catch_test.dart.
    // #3149 — re-grandfathered 1046 → 1077: the startup-brick fix adds
    // the catch-all after the HiveCorruptionException catch (route
    // unknown storage failures to the same StorageRecoveryHost), the
    // Hive-independent StartupFailureStore.persist in both brick paths,
    // and the next-launch replay drain. The store itself is a new file;
    // these lines are only the run()/_launch wiring.
    // #3184 — re-grandfathered 1077 → 1081: the
    // `Obd2ConnectTracePersistence.init()` call (+ import + rationale
    // comment) in the parallel storage-init block, so the persisted
    // connect-trace ring hydrates / registers its export section at
    // startup. The logic lives in the NEW under-cap
    // obd2_connect_trace_persistence.dart.
    // #3126 — re-grandfathered 1081 → 1084: the sync-run-id mint
    // (`SyncRunTrace.begin('launch')` + import) before the launch merges,
    // so the per-table sync counts thread under one run id in the trace.
    // #3144 — re-grandfathered 1084 → 1087: the leveled-log-facade import
    // plus the loop-avoidance rationale comment on the Sentry beforeSend
    // scrub fallback (the 8 remaining info-level debugPrints became
    // `log.info(...)` roughly line-for-line).
    // #3146 — re-grandfathered 1087 → 1090: `HealthCounters.init()` joins
    // the storage-phase `Future.wait` (+ its import) so the always-on
    // counter box opens in the foreground isolate only.
    // #3167 — re-grandfathered 1090 → 1104: the guarded
    // `iosStateRestorationServiceProvider.initialize()` call (+ import +
    // rationale comment) sequenced INSIDE the auto-record orchestrator's
    // deferred block, so Core Bluetooth state restoration is opted in
    // before the orchestrator's first FBP touch. The restoration logic
    // itself lives in the under-cap ios_state_restoration_service.dart /
    // NEW ios_background_adapter_listener.dart; this is launch glue only.
    // #3169 — re-grandfathered 1104 → 1113: `_maybeInitBackground` now
    // also fires `BackgroundService.onOpportunisticWake()` after reconcile
    // (the cold-launch opportunistic alert scan, + rationale comment). The
    // gating/scheduling logic lives in the under-cap background_service.dart;
    // this is launch glue only.
    // #3135 — re-grandfathered 1113 → 1114: the typed-route layer import
    // (core/navigation/app_routes.dart). 14 bumps — decomposition DONE by
    // (AppInitializer phase decomposition).
    // #3139 — shrunk 1113 → 724: the launch sync merges, trip crash
    // recovery, provider warm-ups and the isolate-spool drain moved into
    // ordered phase objects under lib/app/startup/ (all under-cap).
    // What remains is pinned IN PLACE by the structural startup tests
    // (test/app/app_initializer*_test.dart, startup_brick_recovery_test,
    // startup_instrumentation_test): run()'s ordering + brick catches,
    // _initStorage, _maybeInitTankSync, _installErrorHandlers,
    // _stashWidgetLaunchUri, the Sentry gate and the #3149 replay.
    // Snapshot lowered to lock the shrink in (a shrink never bumps).
    'lib/app/app_initializer.dart': (
      lines: 724,
      bumps: 14,
      decompositionIssue: 3139,
    ),
    // #3078 — grandfathered at 414 (was 400, right at the cap on master). The
    // deletion-tombstone fix threads a tombstoned-id set through `merge` and
    // `mergeRows` (fetch + dual-side filter so a delete on another device
    // doesn't resurrect) plus the `deleteSummary` tombstone write — a real
    // fix, not boilerplate. Decomposition of this near-cap file is its own
    // future task.
    'lib/core/sync/trips_sync.dart': (
      lines: 414,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #2415 — background_service.dart graduated: the scan body moved into
    // BackgroundAlertScanCoordinator + BackgroundScanRunners +
    // BackgroundPriceHistoryWriter, so the file dropped from 782 to ~246
    // lines (below the cap). Removed from the snapshot per the shrink
    // ratchet; the extracted files are all new and under 400.
    // #3296 — country_config.dart decomposed (751 → 284): the 17 per-country
    // CountryConfig data rows moved to country_config_data_core.dart (pre-v4.1.0
    // set, 189) + country_config_data_extended.dart (v4.1.0+, 329); each
    // `Countries.<name>` is now a const alias of the matching `k<Name>`, so the
    // ~86 importers + every `Countries.germany`-style call site are unchanged.
    // Removed from the snapshot per the shrink ratchet; both data files < 400.
    // #3232 — country_service_registry.dart decomposed (864 → 241): the data
    // rows moved out into country_service_data.dart (entries + kDefaultFuelTypes,
    // 316) + country_service_policies.dart (the per-service FuelServicePolicy
    // consts, 277), and CountryServiceEntry into country_service_entry.dart (90,
    // re-exported for backward compat). The registry file now holds only the
    // lookups + service builders, below the cap. Removed from the snapshot per
    // the shrink ratchet; the extracted files are all new and under 400.
    // #2969 — re-grandfathered 500 → 522: the `transportForName` inference
    // (matches a stored adapter name against the profile nameMatchers so the
    // transport-aware self-test takes RFCOMM for a Classic-SPP adapter instead
    // of a doomed BLE 4 s-timeout) + its dartdoc. A pure-data lookup append to
    // the existing catalog class.
    // #3014 — re-grandfathered 522 → 556: the dual-transport disambiguation
    // (`transportsForName` + `disambiguateTransport`) — when a name matches BOTH
    // a BLE and Classic profile (SmartOBD / vLinker), prefer bonded-Classic when
    // bonded else BLE — plus dartdoc. Two pure lookup methods on the catalog.
    // #3097 — re-grandfathered 556 → 625: the iOS-BLE-scan fix adds (1) a
    // `discoveryTransport` field on Obd2AdapterCandidate + its dartdoc, (2)
    // resolve() now prefers the discovery transport when a name matches both a
    // BLE and a Classic profile (so a BLE-discovered `OBDII` resolves to a BLE
    // profile, the only transport iOS can use), and (3) a `generic-ble`
    // fallback profile mirroring `generic-classic`'s matchers (shared const)
    // that connects via dynamic GATT discovery. Pure data + lookup growth on
    // the existing catalog class; decomposition tracked by #2190.
    // #3103 — 625 → 693: classify-not-filter (rank surfaces NAMED-unrecognized
    // devices instead of dropping them), the specific-beats-generic resolve
    // pool, broadened `obd`/`elm` generic matchers + `isGeneric`, the
    // `recognized` flag, and the two unrecognized placeholder profiles. Pure
    // data + lookup growth on the existing catalog class; decomposition still
    // tracked by #2190.
    // #3180 — 693 → 697: comment-only growth documenting WHY the OBDLink CX
    // profile is the FFF0/FFF2/FFF1 layout (not the MX+/LX 18F0 it was
    // wrongly pinned to). Decomposition still tracked by #2190.
    // 5 bumps — decomposition forced (#3141), tracked by the OPEN #3140
    // (OBD2 god-class decomposition, successor to the closed #2190 the
    // comments above reference).
    'lib/features/obd2/data/adapter_registry.dart': (
      lines: 697,
      bumps: 5,
      decompositionIssue: 3140,
    ),
    // #2969 — grandfathered at 563 (was 389, under-cap before). The #2969
    // connect-trace instrumentation opens/finalises a trace at the FIVE public
    // connect entry points (the single virtual-dispatch chokepoint every live
    // caller funnels through — this is what makes a FAILED connect leave a
    // trace), records the scan list + resolved transport, and classifies the
    // init failure from the teed transcript. The pure classifier + the trace
    // ring/model were split into separate files (obd2_connect_classifier.dart /
    // obd2_connect_trace_log.dart, both < 400); the remaining bulk is the
    // per-method trace wrappers on this already-near-cap connect service.
    // Further decomposition of this god-class is tracked by #2190.
    // #3009 — re-grandfathered 563 → 570: `_openAndInit` now classifies the
    // engine-off / ECU-silent case (init succeeded but the vehicle bus never
    // answered → busAnswered false) as `ignitionOff` instead of a misleading
    // green `success` (7 lines: the first-wins stamp + its rationale comment).
    // #3014 — re-grandfathered 570 → 601: the adapterName param threaded through
    // every by-MAC connect entry (`connectByMac`/`connectByMacDirect`/
    // `connectByMacClassicDirect`/`connectByMacPassive`/`_traced`) so a connect
    // trace names the adapter, plus the `_inferTransport` registry-hint helper
    // (atop #3009's engine-off classification, both kept on the merge).
    // #3019 — re-grandfathered 601 → 629: Epic #3013 phase 3 auto-pins the
    // last-good adapter on EVERY successful connect at the single `_openAndInit`
    // chokepoint (the `lastGoodAdapterStore` field + ctor param + the
    // best-effort `recordFrom` call + the production-provider wiring). Local-only
    // (Hive settings box), so it stays a small additive thread on the existing
    // connect path rather than warranting a separate connect class.
    // #3025 — re-grandfathered 629 → 668: the transport-aware firstConnect
    // entry (`connectByMacTransportAware` — the thin overridable instance
    // method + its ~30-line dartdoc explaining the vLinker BM-Android root
    // cause). The actual routing body lives in the `obd2_connect_by_mac` part
    // (346, under cap); only the dispatch stub + rationale land here. The class
    // is already split across two `part` files; further decomposition is tracked
    // under #2187/#2188.
    // #3035 — re-grandfathered 668 → 674: the `ignitionOff` classification +
    // auto-pin now gate on the tri-state `Obd2Service.busProbe` (only a
    // CONFIRMED engine-off `probedSilent` stamps `ignitionOff` / skips the
    // pin), so a transient `0100` timeout during the protocol search no longer
    // false-classifies a live car. Net +6 is the rationale + the pinnable
    // guard. Decomposition still tracked under #2187/#2188.
    // #3103 — 674 → 694: the `supportsClassicDiscovery` getter + the
    // Android-only Classic-facade platform gate at the provider seam (+ their
    // rationale comments). #3113 — 694 → 697: connectByMacDirect's timeout made
    // nullable so iOS gets a 7s cold-connect budget (+ rationale comment).
    // #3181 — 697 → 764: first-connect pairing mode in `_openAndInit` (arm /
    // clear Obd2PairingMode around the connect, the `_isFirstConnectDevice`
    // discriminator over KnownObd2AdaptersStore + the last-good pin, the
    // typed Obd2PairingRequired rethrow on a pairing-classified trace
    // outcome) + the knownAdaptersStore field/ctor/provider wiring. The
    // pairing-mode + store logic itself lives in NEW under-cap files
    // (obd2_pairing_mode.dart / obd2_known_adapters_store.dart).
    // Decomposition still tracked under #2187/#2188.
    // #3184 — re-grandfathered 764 → 826: picker-UI scans are now traced
    // too ("I scanned and saw nothing" previously left NO artefact): the
    // `scan()` body gained the pickerScan trace open/outcome/finalise
    // try-finally wrap, the `_stampPinnedIdMismatch` helper (the #3168
    // iOS UUID-vs-MAC identity-drift discriminator), and the provider
    // registers the adapter-state step-0 probe. The persistence layer
    // lives in the NEW under-cap obd2_connect_trace_persistence.dart.
    // #3168 — re-grandfathered 826 → 865: the iOS UUID-rotation rematch
    // wiring (the `onAdapterIdentityRotated` re-persist seam field + its
    // dartdoc, the `connectByMac` scan-loop handoff to the rematch, and
    // the provider's repersist wiring). The rematch decision table +
    // identity capture + re-persist logic all live in the NEW under-cap
    // obd2_adapter_identity.dart; only the seam plumbing lands here.
    // Decomposition still tracked under #2187/#2188.
    // #3185 — re-grandfathered 826 → 899: the single-flight connect
    // SUPERVISOR + scan GOVERNOR are wired at this chokepoint (the whole
    // point of #3185 is that admission lives at the ONE place all six
    // connect owners funnel through): the two fields + ctor params +
    // provider wiring, the thin `supervisor.admit(...)` shells around the
    // seven public connect entries (incl. the passive admitPassive +
    // onPreempt hookup), and the scan() governor gate. The state machines
    // themselves live in the NEW under-cap obd2_connect_supervisor.dart /
    // obd2_scan_governor.dart. Decomposition still tracked under
    // #2187/#2188.
    // (#3168's rematch seam, listed above, adds its 39 lines ON TOP of the
    // #3185 wiring — combined snapshot below.)
    // #3172 — +1: the obd2_platform_budgets.dart import (the BLE-budget
    // consolidation removed two inline forks from this library's part file).
    // 12 bumps — decomposition forced (#3141), tracked by the OPEN #3140
    // (successor to the closed #2187/#2188 the comments above reference).
    'lib/features/obd2/data/obd2_connection_service.dart': (
      lines: 939,
      bumps: 12,
      decompositionIssue: 3140,
    ),
    // #2969 — grandfathered at 419 (was ~399, right at the cap on master). The
    // scan-path BLE `connect()` timeout bound (FBP could otherwise block ~35 s
    // on a vanished candidate) + the channel-open connect-trace stamp (the one
    // place the REAL FBP/StateError is in hand before Obd2Service.connect
    // swallows it). The stamp was already factored to the shared
    // Obd2ConnectTraceLog.stampOpenFailure one-liner.
    // #3014 — re-grandfathered 419 → 655: the Phase-2 reliable-BLE-connect core
    // (Epic #3013). Dart cannot split a single class body across `part` files,
    // so this cohesive BLE channel necessarily carries: scan-before-connect (the
    // SmartOBD GATT-133 fix) behind the injected `scanSeed`; property-based GATT
    // discovery via the pure `resolveElmGatt` (registry UUID hint → family
    // property-match → any-property), with the FAILED-open layout dump; per-step
    // bounded timeouts (discoverServices / setNotifyValue) for distinct
    // gattTimeout vs serviceNotFound outcomes; MTU-in-connect; the
    // `Obd2GattRecoverable.refreshGattCache` (Android clearGattCache) for the
    // 133 retry; and the `connectDevice`/`rawConnect`/`discoverAndBind`/
    // `bindConnectionState` test seams that make all of it unit-testable without
    // a BLE stack. The pure matcher already lives in elm_gatt_profiles.dart.
    // #3019 — re-grandfathered 656 → 678: Epic #3013 phase 3 PROACTIVE BLE-drop
    // detection. The debounce-confirmed disconnect edge (`_onDropConfirmed`) now
    // ALSO emits the transport-agnostic `Obd2LinkDropSignal` (with the `_closing`
    // / `_dropSignalled` guards so a deliberate `close()` is not misread as a
    // drop), so the trip-INDEPENDENT reconnect controller starts immediately
    // rather than waiting for the next failed command. The drop edge already
    // lives here (it cannot leave this cohesive channel body), so the signal is
    // a few additive lines on it, not a new file.
    // #3118 — 678 → 700: the post-connect discover + setNotify timeouts made
    // iOS-aware (const → platform-branching getters + dartdoc) so a slow iOS
    // CoreBluetooth CCCD write no longer clips the OBDLink CX at 4s, plus two
    // @visibleForTesting accessors to lock the budgets. Android byte-identical.
    // #3179/#3182 — 700 → 776: (1) the channel is now safely RE-openable
    // (open() resets the `_closing`/`_dropSignalled` latches, recreates the
    // closed `_incoming` controller + the disposed drop debouncer) so the
    // transport's close()+open() retry no longer yields a zombie link, with
    // the `handleNotifyBytes`/`debugNoteConnectionState` seams that make it
    // testable; (2) the discover/setNotify budgets moved onto FBP's own
    // `timeout:` parameters (mutex-releasing) and the #3182 poweredOn gate
    // runs before connectDevice. Mostly dartdoc explaining the two field
    // failure modes; the drop/reopen state cannot leave this cohesive channel
    // body. Decomposition of the channel is tracked by #2190.
    // #3181 — 776 → 851: the `enableNotify` / `rawSetNotify` seams (the CCCD
    // subscribe is THE pairing trigger on the OBDLink CX): first-connect
    // budget selection via Obd2PairingMode, the pairing-wait UI flag, and
    // the typed Obd2PairingRequired wrap of a pairing-classified setNotify
    // failure — plus their contract dartdoc. The policy itself lives in the
    // NEW under-cap obd2_pairing_mode.dart; only the FBP-touching subscribe
    // can live here.
    // #3184 — 851 → 866: stage-tag steps (`gatt-connect-ok` with elapsed
    // ms + `discover-start` with its budget) in `_connectAndDiscover`, so
    // a connect dying in discover/setNotify is distinguishable from one
    // that never got a GATT link — from ONE field export.
    // 6 bumps — decomposition forced (#3141), tracked by the OPEN #3140
    // (successor to the closed #2190 the comments above reference).
    'lib/features/obd2/data/flutter_blue_plus_elm_channel.dart': (
      lines: 866,
      bumps: 6,
      decompositionIssue: 3140,
    ),
    // #2953 — grandfathered at 405 (5 over): the _probeSafely / _connectSafely
    // catches were rerouted from a raw `errorLogger.log` ERROR spool to the
    // shared `recordObd2ConnectTransient` de-noiser (a parked-car engine-off
    // transient must breadcrumb, not spool an ERROR every backoff cycle —
    // #2892/#2935/#2945 never reached this site) via a small shared `_denoise`
    // helper + its dartdoc. The net push just past 400 is a real fix; further
    // compression would hurt readability. Decomposition tracked by #2187/#2188.
    'lib/features/obd2/data/adapter_reconnect_scanner.dart': (
      lines: 405,
      bumps: 0,
      decompositionIssue: null,
    ),
    'lib/features/obd2/data/auto_trip_coordinator.dart': (
      lines: 726,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #3279 — elm327_parsers.dart decomposed below the cap (419 → 345): the
    // final slice moved the shared decode plumbing — `cleanResponse`
    // (→ `cleanElmResponse`), the Mode 01 framing helper `_parseModeOneBody`
    // (→ `parseModeOneBody`), and the PID-0x51 `fuelTypeCodeToProfileKey` map —
    // into `elm327_decode_util.dart` (now 115), next to the
    // `parseElmHexBytes` / `isPlausibleOdometerKm` helpers the earlier slices
    // moved there. `Elm327Parsers.cleanResponse` stays as a thin delegating
    // stub for its public callers. Removed from the snapshot per the shrink
    // ratchet; the util stays well under 400.
    // #2456 — re-grandfathered 471 → 524: the live integrator gained λ
    // (PID 0x44, 2 Hz) + baro (PID 0x33, 0.5 Hz) supportsPid-gated
    // subscriptions and threads both into the MAF + speed-density fuel
    // derivation (effective AFR + air-density correction). Decomposition
    // is tracked separately by #2187/#2188.
    // #2457 — re-grandfathered 524 → 533: subscribeAllTiers re-expressed
    // as four cadence tiers (PidTier) + the centralised `_sub` helper that
    // carries the discover-all ∩ target-set gate (optionalPid) so each PID
    // is a one-line tier assignment, with #2458 tier slots commented in.
    // Net +9 is the helper + its dartdoc, not new branching. Decomposition
    // is tracked separately by #2187/#2188.
    // #2458/#2459 — re-grandfathered 533 → 652: filled the #2457 tier
    // slots with nine supportsPid-gated subscriptions (pedal D/E/F →
    // dynamics, abs-load → mixture, bank-2 trims → slow, oil + ambient →
    // thermal) + their latches and latest-value getters that `_emit`
    // persists onto each TripSample (#2459), + the bank-2 fold into
    // `_applyTrim`. Each is a one-line `_sub` call carrying its own gate.
    // Decomposition is tracked separately by #2187/#2188.
    // #2648 — re-grandfathered 652 → 673: GPS horizontal accuracy +
    // bearing latches (2 fields + 2 getters + 2 updateGpsFix params, all
    // null-guarded like altitude) so the OBD2 emit path stops dropping
    // them (they reached only 0.3 % of samples). Net +21; decomposition
    // is still tracked by #2187/#2188.
    // #2692 C4-B — re-grandfathered 673 → 674: one comment line documenting
    // the altitude isFinite chokepoint guard (NaN altitude was poisoning the
    // RoadGradeCalculator on ~22 % of the 77-trip backup). The guard itself
    // is a net-neutral token swap; only the explanatory comment adds a line.
    // 5 bumps — decomposition forced (#3141), tracked by the OPEN #3140
    // (successor to the closed #2187/#2188 the comments above reference).
    'lib/features/obd2/data/live_sample_snapshot.dart': (
      lines: 674,
      bumps: 5,
      decompositionIssue: 3140,
    ),
    // #2379 — re-grandfathered 1457 → 1468: threaded the
    // `logFailureAsError` flag through `connect()` (param + doc + the
    // guarded `if` around the now-conditional connect-failed trace) so a
    // recoverable connect attempt stops flooding the error log. Net +11;
    // decomposition is tracked separately by #2187/#2188.
    // #2456 — re-grandfathered 1468 → 1505: two new read helpers
    // (`readBaroPressureKpa` PID 0x33, `readCommandedEquivalenceRatio`
    // PID 0x44) + their supportsPid-gated use in the MAF + speed-density
    // steps of `readFuelRateLPerHour` + the new optional params on the
    // `estimateFuelRateLPerHourFromMap` forwarder. Decomposition tracked
    // by #2187/#2188.
    // #2465 — re-grandfathered 1505 → 1552: the connect/init path now tees
    // the gated comm-health diagnostics — a `linkKind` field, a
    // `beginSession` + `recordAdapterIdentity` stamp, and the two
    // `recordHandshakeLine` tees alongside the existing
    // `Obd2DebugSessionRecorder.recordHandshakeCommand` calls (all
    // `if(!enabled)`-gated, no-op in prod). Decomposition tracked by
    // #2187/#2188.
    // #2458 — re-grandfathered 1552 → 1599: bank-2 trim folded into
    // `_applyFuelTrimCorrection` (supportsPid-gated PIDs 0x08/0x09) + the
    // updated `applyFuelTrimCorrection` static forwarder + three new read
    // helpers (bank-2 STFT/LTFT, absolute load 0x43). Decomposition tracked
    // by #2187/#2188.
    // #2763 — 1599 → 1603: route the best-effort readVin catch through
    // recordObd2ReadFailure (de-noise flaky-comms timeouts to breadcrumbs) +
    // its import. Decomposition still tracked by #2187/#2188.
    // #2892 — re-grandfathered 1603 → 1618: the `busAnswered` getter (a
    // silent-bus signal: protocol-cached OR ≥1 PID) + its 11-line dartdoc, so
    // the recording coordinator can surface "turn the ignition on" instead of
    // a silent green connect into a degraded GPS-only trip. Decomposition of
    // this god-class still tracked by #2187/#2188.
    // #3035 — re-grandfathered 1618 → 1644: the `busProbe` getter (the
    // tri-state `0100` probe outcome — answered / probedSilent / transient /
    // notProbed) + its 18-line dartdoc + the re-export of Obd2BusProbeResult,
    // so the connection layer gates `ignitionOff` on the CONFIRMED-silent
    // case only and a slow-but-live car is never wrongly told "engine off".
    // The resilient first-`0100` probe itself lives in the new (under-cap)
    // supported_pids_probe.dart. Decomposition still tracked by #2187/#2188.
    // #3037 — re-grandfathered 1644 → 1673: the `_sendWithProtocolSearchWindow`
    // helper (sends the `0100` probe through the transport's GENEROUS
    // protocol-search read window via Obd2ProtocolSearchTransport so the ELM327
    // auto-search resolves within ONE read instead of being re-sent — the root
    // fix for the false engine-off on a slow link) + its dartdoc + the
    // resolver's `searchSend:` wiring + the probe-constant import. The probe
    // logic itself stays in the under-cap supported_pids_probe.dart;
    // decomposition of this god-class still tracked by #2187/#2188.
    // #3181 — 1673 → 1688: the connect-catch now stamps a TYPED
    // Obd2PairingRequired onto the active connect trace (first-wins) before
    // the never-throws `false` return flattens it, so `_openAndInit` can
    // rethrow the typed pairing error (+ the trace-log imports + rationale).
    // #3146 — re-grandfathered 1688 → 1689: the three always-on
    // `healthCounters` connect-rate taps (attempts / successes / failures)
    // + import + rationale comment, so a slowly-failing BLE adapter is
    // visible in the error-log export.
    // 10 bumps — decomposition forced (#3141), tracked by the OPEN #3140
    // (Obd2Service is named in that issue's breakdown).
    'lib/features/obd2/data/obd2_service.dart': (
      lines: 1689,
      bumps: 10,
      decompositionIssue: 3140,
    ),
    // #2428 — re-grandfathered 1235 → 1241: the recoverable VIN-read catch
    // dropped its `errorLogger.log([storage], …)` (and the now-unused
    // error_logger import, −1 line) in favour of a `debugPrint` breadcrumb
    // + an 8-line comment documenting WHY the transient is reclassified
    // (matching the #2379/#2424 precedent in this same map). Net +6: the
    // explanatory rationale, not behaviour. Decomposition of this god-class
    // is tracked under #2187/#2188/#2190.
    // #2459 — re-grandfathered 1241 → 1288: the per-trip 'diagnostic
    // capture' flag (field + dartdoc + slow-cadence interval/guard) and
    // the `_emit` stamping of the six consumed-but-unstored signals
    // (λ/baro/absLoad/pedal/oil/ambient) + the slow-cadence raw mixture
    // inputs (MAF/MAP/STFT/LTFT). Decomposition tracked by #2187/#2188/#2190.
    // #2506 — re-grandfathered 1288 → 1360: the live GPS-physics estimate +
    // coaching + GPS speed/distance fallback for no-fuel-PID cars. The
    // SUBSTANTIVE new logic (the per-fix fold, the coaching window, and the
    // reading-overlay) was extracted to the new pure-Dart
    // `gps_live_estimate_folder.dart` (shared with the GPS-only pipeline so
    // they can't diverge); only the controller-local WIRING remains here —
    // the injected folder field + GPS-speed latch + coaching getter, the
    // `updateGpsFix(speedKmh:)` latch, the `_emit` effective-speed/distance
    // fallback, and the no-fuel-PID overlay call. Decomposition of this
    // god-class is tracked by #2187/#2188/#2190.
    // #2509 + #2513 — re-grandfathered 1360 → 1412 (merge of both): the GPS
    // start-time fallback (the `_gpsStartedAt`/`_gpsEndedAt` latch in
    // `updateGpsFix`, the `_finaliseSummary` start/end back-fill, and the
    // `gpsFixCount` getter the persist guard reads, #2509) PLUS the
    // wider-range absolute load (PID 0x43) + latest GPS altitude wired to
    // the baseline recorder so the fuzzy path can fill the climbing/loaded
    // bucket from a real road grade and/or load ramp (#2513). Pure wiring;
    // decomposition of this god-class is tracked by #2187/#2188/#2190.
    // #2524 — re-grandfathered → 1471: the in-trip reconnect now swaps the
    // controller's live service (`_service` made mutable + the new
    // `replaceService` method that points the recording loop at the
    // reconnected transport AND tears down the dead one) plus the
    // `_DroppedSessionHostAdapter.disconnectDroppedService` hook that fails
    // the dead transport's stranded `_pending` on a drop. Before this the
    // loop polled the DEAD old transport forever → silent data loss + a
    // timeout/StateError flood. Pure recovery wiring; decomposition of this
    // god-class is tracked by #2187/#2188/#2190.
    // #2515 — re-grandfathered 1471 → 1484: the live reading now carries
    // the eight precision signals the calibration path consumes
    // (oil/ambient temp + λ/baro/MAP/STFT/LTFT/pedal), each stamped from
    // an existing snapshot latest-getter in `_emit` (+a shared dartdoc
    // comment). Pure field-plumbing onto the existing TripLiveReading
    // build; decomposition of this god-class is tracked by
    // #2187/#2188/#2190.
    // #2565 — re-grandfathered 1484 → 1595: the GPS-DEGRADE fallback adds
    // the `degradedGpsOnly` ACTIVE state, the `_degradedGpsOnly` latch +
    // `gpsAlive` host wiring, a `_gpsAliveWindow` const, the `_emit`
    // degrade guard, the shared `_overlayGpsEstimate` (extracted from the
    // healthy `_emit` so both paths can't diverge), and the thin
    // delegation + constructor wiring for the new emit collaborator. The
    // bulk WAS extracted out of this file: `GpsOnlySampleBuilder`,
    // `DegradedGpsEmitter` and the `DroppedSessionManager` repo resolver
    // are all new files under the cap. The residual growth is the field
    // plumbing + the host/state-machine seam that must live on the
    // controller. Decomposition of this god-class stays tracked by
    // #2187/#2188/#2190.
    // #2648 — re-grandfathered 1595 → 1621: GPS horizontal accuracy +
    // bearing now thread through the controller's `updateGpsFix` (2
    // params + doc) → `_liveSampleSnapshot.updateGpsFix`, are stamped in
    // `_emit` + the degraded-emit call site, and exposed via two
    // `@visibleForTesting` debug getters. Net +26; the field plumbing
    // must live on the controller seam. Decomposition stays tracked by
    // #2187/#2188/#2190.
    // #2653 — re-grandfathered 1621 → 1623: the `_recorder.onSample`
    // call now threads the live `distanceSource` (+ a 2-line rationale
    // comment) so the harsh-event detector suppresses scoring on the
    // `virtual` dead-reckoning source. Net +2; the wiring must live at the
    // controller's emit site. Decomposition stays tracked by #2187/#2188.
    // #2663 — re-grandfathered 1623 → 1626: the ctor gained an optional
    // `onHarshEvent` callback (forwarded into the default TripRecorder) +
    // a rationale comment, so harsh events stream live to the driving-coach
    // voice listener (the dead-link fix). Net +3 (HarshEvent resolves via
    // the existing trip_recorder re-export, no new import); the wiring must
    // live where the controller builds its recorder. Decomposition stays
    // tracked by #2187/#2188.
    // #2671 — re-grandfathered 1626 → 1636: the OBD2 drop-pause fix wires the
    // scheduler's new pause()/resume() through the DroppedSessionHost adapter
    // (two thin wrappers mirroring the existing stopScheduler) + a resume()
    // call on the drop→reconnect transition with a rationale comment, so a
    // flapping link no longer dispatches PIDs into a dead channel. Net +10;
    // the wiring must live at the controller's host adapter + resume site.
    // Decomposition stays tracked by #2187/#2188.
    // #2767 — re-grandfathered 1636 → 1640: a thin `reconnectPassiveWaiting`
    // getter (delegating to the DroppedSessionManager) surfaces the reconnect
    // scanner's give-up-and-passive-wait state into the UI for the calmer
    // banner copy. Net +4 (getter + 2-line dartdoc); a pure read-through that
    // must live on the controller's public surface. Decomposition stays
    // tracked by #2187/#2188.
    // #2835 — re-grandfathered 1640 → 1641: one import of the shared
    // trip-consumption-reliability gate so `_finaliseSummary` re-applies
    // the tiny-distance L/100 km floor against the swapped odometer
    // distance (the code change itself is net-zero). Decomposition stays
    // tracked by #2187/#2188.
    // #2907 — re-grandfathered 1641 → 1666: the reconnect-RECOVERY core fix.
    // `_runTransport` now routes every poll through `_sendOrShortCircuit`,
    // which fails FAST with a recoverable typed disconnect when the service is
    // no longer connected (never poll a DEAD transport / never orphan a
    // just-reconnected one), and `replaceService` resets the drop detector at
    // the swap so the new live link starts from a clean streak. Both are
    // load-bearing recovery logic in the hot polling path that cannot move out
    // of the controller. Decomposition stays tracked by #2187/#2188.
    // #2963 — re-grandfathered 1666 → 1694: the short-idle-OBD2-trip
    // corruption fix. `updateGpsFix` now forwards the fix's accuracy +
    // timestamp to the haversine distance source (reject parked-car jitter +
    // a cold-start teleport), and the `_emit` speed-persist guard stops
    // `speedKmh ?? 0` fabricating a leading `0` that scored a phantom
    // hard-accel. Both are hot-path recording logic that can't move out of
    // the controller. Decomposition stays tracked by #2187/#2188.
    // #3004 — re-grandfathered 1694 → 1707: the `debugAppendGpsFix` test seam
    // gains optional `hAccuracyM` / `at` params (forwarded to the resolver,
    // matching production `updateGpsFix`) so a test can drive the new ~1 Hz
    // GPS-track decimation deterministically. Test-only surface; decomposition
    // stays tracked by #2187/#2188.
    // #3029 — re-grandfathered 1707 → 1717: a 9-line parity-rationale comment
    // at `_finaliseSummary` documenting why this OBD2 path (no IMU detector)
    // is already correct after the recorder suppresses GPS-derived harsh
    // scoring — i.e. why no #2895 IMU-veto wiring is needed here. Doc-only;
    // decomposition stays tracked by #2187/#2188.
    // 17 bumps (the worst offender in this map) — decomposition forced
    // (#3141), tracked by the OPEN #3140 (TripRecordingController is
    // named in that issue's breakdown).
    'lib/features/obd2/data/trip_recording_controller.dart': (
      lines: 1717,
      bumps: 17,
      decompositionIssue: 3140,
    ),
    // #2798 — grandfathered at 408 (8 over): the pump path now retries OCR
    // with a contrast-stretched GRAYSCALE pass when the #2275 binarized pass
    // recovers nothing (the binarization erased faint 7-seg value digits). The
    // retry + its parseFor helper + the threaded `binarize` flag push this just
    // past 400; further compression would hurt readability of a real fix.
    'lib/features/consumption/data/receipt_scan_service.dart': (
      lines: 408,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #2442 — re-grandfathered 496 → 513: the save flow now raises the
    // guided reconciliation workflow after a plein save (a 7-line
    // await-then-route call into the extracted
    // `runReconciliationWorkflowIfPending` launcher + its rationale
    // comment). The workflow + apply logic itself lives in the extracted
    // launcher/widget; only the trigger call stays on the screen.
    // Decomposition of this god-class is tracked under #2187/#2188/#2190.
    // #2689 — re-grandfathered 513 → 526: the e-receipt Phase 1 plumbing
    // adds the `_scannedPricePerLiter` state field (+ dartdoc), its
    // `setScannedPricePerLiter` wiring in `_buildScanHostState`, and the
    // `scannedPricePerLiter:` arg on the saved `FillUp` (+ rationale) so the
    // exact receipt-scanned unit price is persisted instead of discarded.
    // Pure field plumbing; decomposition stays tracked under #2187/#2188/#2190.
    // #2735 — re-grandfathered 526 → 537: initState now kicks the inbound
    // OS share-intent receipt scan via `scheduleSharedReceiptScanIfPending`
    // (the consume + post-frame + OCR body lives in
    // `fill_up_share_scan_handlers.dart`, NOT here, to keep this file's
    // growth to the call site + dartdoc). Decomposition stays tracked under
    // #2187/#2188/#2190.
    // #2838 — realign 537 → 539: the actual file already stood at 539 on
    // master (#2840/#2841 grew it +2 without bumping this snapshot). The
    // share-intent text-prefill wiring here is net-zero on the file (the
    // single existing `scheduleSharedReceiptScanIfPending` call site was
    // renamed in place to `scheduleSharedReceiptPrefillIfPending`, which
    // drains both stashes), so this only corrects the snapshot to reality.
    // #2836 — re-grandfathered 539 → 588: the data-quality save gate
    // (_confirmDataQualityWarnings) must read the State's controllers +
    // providers, so it lives here; the pure warning logic + the dialog
    // are extracted (add_fill_up_warnings.dart, fill_up_warning_dialog.dart)
    // to keep the growth to the gate method + its call site. Decomposition
    // stays tracked under #2187/#2188/#2190.
    // #2886 — +41: multi-fuel per-fill prompt — `_safeFillUps` helper +
    // the resolver re-seeding from last-used fuel on both the init and
    // vehicle-change paths. Decomposition stays tracked under #2187.
    // #2687 — re-grandfathered 629 → 638: the manual "paste receipt text"
    // entry point — the `fill_up_paste_receipt_handler.dart` import + the
    // 6-line `_pasteReceiptText` delegator (cohesive with the adjacent
    // `_scanReceipt`/`_scanPumpDisplay` cluster) + the `onPasteReceipt`
    // callback wiring. The dialog + parse-and-prefill body live in the
    // extracted handler file; only the thin delegation lands here.
    // Decomposition stays tracked under #2187.
    // #3073 — +11 → 649: app-bar check action (save above the iOS keyboard,
    // which covers the bottom save bar and has no system dismiss) + onDrag
    // keyboard dismissal. Small iOS bug fix; decomposition still tracked (#2187).
    // 8 bumps — decomposition forced (#3141), tracked by the OPEN #3138
    // (trips/fillups feature split; this screen is fill-ups).
    'lib/features/consumption/presentation/screens/add_fill_up_screen.dart': (
      lines: 649,
      bumps: 8,
      decompositionIssue: 3138,
    ),
    // #2380 — +5: closest-station radar card at the top of the
    // recording column + a SingleChildScrollView wrap so the longer
    // column (radar + 5 metric cards + coaching card) scrolls instead
    // of overflowing on short viewports.
    // #2391 — re-grandfathered 1069 → 1074: GPS-only Avg card now shows
    // the measured-vs-estimate (`~`) decision via the extracted
    // `TripAvgConsumptionCard` widget (the substantial logic moved off
    // the screen), and the Fuel-used card gained a GPS-estimate fallback
    // branch. Decomposition tracked under the existing god-class
    // follow-ups (#2187/#2188/#2190).
    // #2509 — re-grandfathered 1074 → 1088: the `_onStop` handler now
    // surfaces a localized "no movement detected" SnackBar when the stop
    // returned a stationary discard (`StoppedTripResult.discardedNoMovement`),
    // so a Stop tap that saves nothing is never silent data loss. Pure UI
    // wiring; decomposition tracked under #2187/#2188/#2190.
    // #2548 — re-grandfathered 1088 → 1105: `_buildRecording` now renders the
    // inline `TripSaveProgress` card during the transient `saving` phase (the
    // stop-side bookend to the connecting view) plus a saving AppBar-title
    // variant — staged save feedback. Pure UI wiring; decomposition still
    // tracked under #2187/#2188/#2190.
    // #2569 — re-grandfathered 1105 → 1113: a one-line `ref.watch` of the
    // voice-announcement listener in `build` (keeps the keepAlive listener
    // mounted while the screen is up) plus its import + an explaining
    // comment. Pure wiring; decomposition still tracked under #2187/#2188.
    // #2663 — re-grandfathered 1113 → 1123: a one-line `ref.watch` of the
    // NEW driving-coach voice listener in `build` (the missing
    // event→coach→speak wire — keeps the keepAlive listener mounted while
    // the screen is up) plus its import + an explaining comment. Pure
    // wiring; decomposition still tracked under #2187/#2188.
    // #2764 — shrank 1123 → 1090: the 5 inline app-bar IconButtons moved
    // into the new RecordingAppBarActions widget (Pause + Stop primary,
    // Pin/Help/PiP folded into an overflow kebab). Net -33 lines here.
    // #2903 — grew 1090 → 1106 (+16): the landscape orientation dispatch.
    // The bulk of the landscape layout was extracted to the new
    // trip_recording_landscape_body.dart (262 lines); only the
    // MediaQuery.orientation branch + its import remain here. Full
    // decomposition of this screen still tracked under #2187/#2188.
    // #3135 — re-grandfathered 1106 → 1107: the typed-route layer import
    // (core/navigation/app_routes.dart) so the exit navigation uses
    // RoutePaths.search instead of a banned string literal. Pure import
    // line; no logic added.
    // 8 bumps — decomposition forced (#3141), tracked by the OPEN #3138
    // (trips/fillups feature split; this screen is trips).
    'lib/features/consumption/presentation/screens/trip_recording_screen.dart':
        (lines: 1107, bumps: 8, decompositionIssue: 3138),
    'lib/features/consumption/presentation/widgets/broken_map_widgets.dart': (
      lines: 439,
      bumps: 0,
      decompositionIssue: null,
    ),
    // errorlog_30 — re-grandfathered 439 → 458: `_connect` now captures the
    // active profile + vehicle-list notifier BEFORE its first `await` and
    // threads them into `_persistPickedAdapterToActiveVehicle`, so the
    // post-connect persist never touches `ref` after the sheet unmounts (the
    // real Open-Testing "ref used after unmount" StateError). The growth is the
    // two captures + the two extra params + the rationale comments; it cannot
    // move out of the State. Decomposition stays tracked under #2187/#2188.
    // #3025 — re-grandfathered 458 → 470: the pinned-MAC fast path now routes
    // through the TRANSPORT-AWARE `connectByMacTransportAware` (a Classic
    // adapter — vLinker BM-Android — must never take the BLE GATT path that
    // 4 s-times-out + poisons the RFCOMM socket) instead of the BLE-leaning
    // scan-based `connectByMac`. The growth is the swapped call + its rationale
    // comment. Decomposition stays tracked under #2187/#2188.
    // #3103 — 470 → 515: two-section selecting view (recognized adapters, then
    // a "other devices — tap to try" section for NAMED-unrecognized devices) +
    // the iOS "BLE adapters only" notice + the shared `_candidateTile` helper.
    // #3181 — 515 → 543: the pairing-wait hint under the connecting spinner
    // (ValueListenableBuilder on Obd2PairingMode.pairingWaitPending — the OS
    // pairing dialog otherwise makes the spinner look hung) + the pinned
    // fall-through snackbar carrying the pairing guidance instead of the
    // generic "couldn't reach" text. Decomposition stays tracked under
    // #2187/#2188.
    // #3184 — 543 → 552: cancel the scan-stream subscription
    // (fire-and-forget) before the connect begins + the captured
    // connection read, so the connect opens its OWN trace (beginTrace
    // supersedes a live pickerScan trace) instead of the scan's absorbing
    // it. Decomposition stays tracked under #2187/#2188.
    // #3164 — re-grandfathered 552 → 555: errorLogger routing adds 3 lines
    // (the connect-failure catch now logs e/st before the mounted check).
    // 6 bumps — decomposition forced (#3141), tracked by the OPEN #3140
    // (successor to the closed #2187/#2188 the comments above reference).
    'lib/features/obd2/presentation/widgets/obd2_adapter_picker.dart': (
      lines: 555,
      bumps: 6,
      decompositionIssue: 3140,
    ),
    // #2624 — shrank 463 → 450: dropped the post-frame `fitCamera` block
    // (+ its dart:async / error_logger imports) in favour of
    // `MapOptions.initialCameraFit`, fixing the grey-tile cold-start race.
    'lib/features/consumption/presentation/widgets/trip_path_map_card.dart': (
      lines: 450,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #2441 — re-grandfathered 879 → 911: split the trip-vs-pump
    // reconciliation into a detect-vs-apply seam. The detector still
    // lives in reconciler.dart; the apply step (`applyReconciliation`)
    // and the surface-or-clear branch must stay on `FillUpList` because
    // they mutate its state. The PendingReconciliation value object and
    // the PendingReconciliations notifier were already extracted to
    // their own files; only the seam wiring remains here.
    // #2442/#2444 — re-grandfathered 911 → 964: the silent save is gone
    // (the seam now only publishes the gap), and the two CONSENTED apply
    // paths landed here — `applyReconciliation` (Path A, consented
    // correction) and `applyVirtualTrajet` (Path B, virtual trajet).
    // Both must stay on `FillUpList` / its trip-history sibling because
    // they mutate provider state; the workflow UI + launcher are
    // extracted. Decomposition tracked under #2187/#2188/#2190.
    // #2445 — re-grandfathered 964 → 975: the surface-or-clear branch
    // gained a keep-prior-gap guard so a clean later plein never silently
    // drops a still-unresolved deferred gap (the decision is never lost).
    // Lives on `FillUpList` because it reads + mutates the pending-gap
    // provider in the same save path. Decomposition tracked #2187/#2188.
    // #3077 — re-grandfathered 975 → 1005: `FillUpList.pullFromServer`
    // (the unit-tested server→local fill-ups pull-persist seam, local wins
    // on id collision) + the `FillUpsMergeFn` typedef + the fill_ups_sync
    // import. Sibling of the existing device-link `mergeFrom`. Decomposition
    // of this god-class is tracked #2187/#2188.
    // #3122 — re-grandfathered 1005 → 1025: the LWW `updatedAt` stamps on
    // the five fill-up/vehicle mutation paths + the changed-entry filter in
    // `pullFromServer` (server-newer overwrites). Decomposition is still
    // tracked #2187/#2188.
    // 5 bumps — decomposition forced (#3141), tracked by the OPEN #3138
    // (this providers file / FillUpList is named in that issue).
    // #3138 — ratcheted DOWN 1025 → 938: the duplicated plein-to-plein window
    // math in the FillUpList notifier's `_linkedTripIdsForWholeWindow` +
    // `_relinkOpenWindow` moved into the pure, unit-tested FillUpTripLinker
    // (domain/services/fill_up_trip_linker.dart). First #3138 slice; the
    // trips/fillups feature split is the remaining work.
    'lib/features/consumption/providers/consumption_providers.dart': (
      lines: 938,
      bumps: 5,
      decompositionIssue: 3138,
    ),
    // #2509 — re-grandfathered 1180 → 1217: the persist guard in
    // `_saveToHistory` was tightened from the buggy disjunction
    // (`startedAt == null || distance < 0.01`, which silently discarded a
    // real GPS-tracked drive with a dead OBD2 link) to the conjunction
    // #1923 intended, `_saveToHistory` now returns a `TripPersistOutcome`,
    // and a genuine stationary discard logs a structured `errorLogger`
    // entry (no more silent discard). The `_RecordingPipelineHostAdapter`
    // forwards the new `gpsFixCount` param + return type. Pure wiring +
    // rationale; decomposition of this god-class is tracked #2187/#2188/#2190.
    // #2392 — re-grandfathered 1125 → 1162: wired the OBD2-ground-truth
    // physicsScale calibration into `_saveToHistory` (one fire-and-forget
    // call + the `_calibratePhysicsScale` resolve/persist helper; the EWMA
    // math itself lives in the standalone `PhysicsScaleCalibrator`).
    // Decomposition of this god-class is tracked under #2187/#2188/#2190.
    // #2459 — re-grandfathered 1162 → 1180: the `_readDiagnosticCaptureFlag`
    // closure (mirrors `_readOemPidsFlag`: reads Feature.debugMode, swallows
    // provider-wiring errors → safe off) + its injection into the pipeline.
    // Decomposition tracked by #2187/#2188/#2190.
    // #2548 — re-grandfathered 1217 → 1235: the `setSaveStage` notifier method
    // + its `_RecordingPipelineHostAdapter` override + the TripSaveStage
    // re-export — the staged save-progress wiring mirroring `setConnectStage`.
    // Decomposition still tracked by #2187/#2188/#2190.
    // #2565 — re-grandfathered 1235 → 1240: the WAL-snapshot phase-string
    // switch gained the `degradedGpsOnly` case (mapped to 'recording' — a
    // degraded trip is still actively recording) + its rationale comment.
    // Pure mapping; decomposition still tracked by #2187/#2188/#2190.
    // #2787 — 1240 → 1246: the no-movement discard now only error-logs when
    // captured signal is actually dropped (the droppedCapturedSignal guard +
    // its comment), so an empty stop no longer spams the error log.
    // #2912 — 1246 → 1250: `_saveToHistory` now captures + persists the
    // per-trip OBD2 comm-health diagnostic (the never-throws `captureForTrip`
    // call + the `obd2Diagnostic` constructor arg) so the always-empty card is
    // fixed. Minimum footprint for a new persisted field; the god-class
    // decomposition stays tracked by #2187/#2188/#2190.
    // 7 bumps — decomposition forced (#3141), tracked by the OPEN #3140
    // (the trip-recording pipeline; successor to the closed
    // #2187/#2188/#2190 the comments above reference).
    'lib/features/consumption/providers/trip_recording_provider.dart': (
      lines: 1250,
      bumps: 7,
      decompositionIssue: 3140,
    ),
    'lib/features/feature_management/data/legacy_toggle_migrator.dart': (
      lines: 647,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #3233 — station_map_layers.dart graduated (700 → 354, below the cap):
    // the pure geometry/marker-ranking statics → station_map_geometry.dart
    // (#3289), the marker-model pipeline → station_marker_model_builder.dart +
    // the zoom controls → map_zoom_controls.dart (#3295), and the FlutterMap
    // layer tree → station_map_body.dart (the presentational StationMapBody,
    // this PR). The widget now holds only the memoised marker model + the
    // camera-fit lifecycle. Removed from the snapshot per the shrink ratchet;
    // every extracted file is new and under 400.
    // #2510 — re-grandfathered 544 → 562: the nearby-search map no longer
    // #2681 — feature_management_section.dart graduated: the #2681 ordered-
    // category reorg decomposed the 718-line god-class into the
    // widgets/feature_management/ folder (conso_feature_card.dart,
    // feature_group_card.dart, feature_localization.dart,
    // feature_grouping.dart, feature_section_header.dart) so the section
    // dropped to ~168 content lines (below the cap). Removed from the
    // snapshot per the shrink ratchet; every extracted file is new and
    // under 400.
    // #3234 — vehicle_profile.dart decomposed (491 → 377): the powertrain /
    // calibration-mode / connector enums and their enum-only JSON converters
    // moved into vehicle_enums.dart (132, re-exported for backward compat), so
    // the freezed entity file holds only the model + ChargingPreferences and
    // drops below the cap. Removed from the snapshot per the shrink ratchet;
    // vehicle_enums.dart is new and under 400. The sibling edit_vehicle_screen
    // decomposition stays tracked by the (still-open) #3234.
    // #3234 — edit_vehicle_screen.dart graduated (879 → 308, below the cap):
    // the imperative form actions + the mutable form state moved into the
    // `_VehicleEditActions` part mixin (edit_vehicle_screen_actions.dart, 358),
    // and the form body (the PageScaffold + section-card stack) into the
    // presentational VehicleEditForm (vehicle_edit_form.dart, 281). The screen
    // now holds only the load/dispose lifecycle, the prepop `ref.listen`, the
    // discard `PopScope`, and `build`. Removed from the snapshot per the shrink
    // ratchet; both new files are under 400. Closes the #3234 decomposition.
    'lib/features/vehicle/presentation/widgets/auto_record_section.dart': (
      lines: 830,
      bumps: 0,
      decompositionIssue: null,
    ),
    // #2837 — re-grandfathered 465 → 523: on a direct-fuel-rate (PID 5E)
    // car the η_v field + its "0 samples" learner readout + Reset learner
    // are replaced by an explanatory _DirectFuelRateNote, since η_v never
    // touches the direct branch. The note widget + the conditional
    // rendering account for the growth. Decomposition tracked under
    // #2187/#2188.
    'lib/features/vehicle/presentation/widgets/calibration_section.dart': (
      lines: 523,
      bumps: 1,
      decompositionIssue: null,
    ),
    'lib/features/widget/data/home_widget_service.dart': (
      lines: 696,
      bumps: 0,
      decompositionIssue: null,
    ),
  };

  bool isScanned(String path) {
    if (!path.endsWith('.dart')) return false;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return false;
    }
    // `flutter gen-l10n` output — generated, not handwritten.
    if (path.startsWith('lib/l10n/')) return false;
    return true;
  }

  int effectiveLines(File file) {
    final rawLines = file.readAsLinesSync();
    // The standard MIT SPDX header (#2053) adds 3 lines at the top of
    // every file (copyright, SPDX-License-Identifier, blank). Discount
    // it so the 400-line norm measures actual content, not boilerplate.
    final headerOffset =
        rawLines.length >= 2 &&
            rawLines[0].contains('Copyright (c) 2026 Florian DITTGEN') &&
            rawLines[1].contains('SPDX-License-Identifier')
        ? 3
        : 0;
    return rawLines.length - headerOffset;
  }

  test('no new Dart file in lib/ exceeds $lineLimit lines (#1680)', () {
    final offenders = <String>[];
    final stillOver = <String>{};
    // Growth ratchet violations: grandfathered file grew beyond snapshot.
    final grownFiles = <String>[];
    // Decomposition candidates: grandfathered files now in 400-800 band.
    final decompositionCandidates = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!isScanned(path)) continue;
      final lines = effectiveLines(entity);

      if (grandfatheredSnapshot.containsKey(path)) {
        if (lines > lineLimit) {
          stillOver.add(path);
          // Growth ratchet (#2351): fail if current > snapshot.
          final snapshot = grandfatheredSnapshot[path]!.lines;
          if (lines > snapshot) {
            grownFiles.add(
              '$path  ($lines lines, snapshot $snapshot, '
              'grew by ${lines - snapshot})',
            );
          }
          // Soft signal: grandfathered files in the 400-800 band are
          // prime decomposition candidates (#2187/#2188/#2190).
          if (lines <= 800) {
            decompositionCandidates.add('$path  ($lines lines)');
          }
        }
        // lines <= lineLimit → file graduated; stale-baseline check below.
      } else if (lines > lineLimit) {
        offenders.add('$path  ($lines lines)');
      }
    }

    // Soft print: list near-cap grandfathered files as decomposition hints.
    if (decompositionCandidates.isNotEmpty) {
      // ignore: avoid_print
      print(
        '\n[file_length_test] Decomposition candidates '
        '(grandfathered, 400-800 lines):\n'
        '${decompositionCandidates.join('\n')}\n',
      );
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'New / un-grandfathered Dart file(s) over $lineLimit lines. '
          'Decompose the file below the limit — splitting widgets, '
          'helpers, or providers into their own files. Offenders:\n'
          '${offenders.join("\n")}',
    );

    // Growth ratchet (#2351): a grandfathered file must not grow beyond
    // its snapshot line count.
    expect(
      grownFiles,
      isEmpty,
      reason:
          'Grandfathered file(s) have GROWN beyond their snapshot. '
          'Decompose the file or update the snapshot in this test with '
          'a comment explaining why more lines are justified — and '
          'increment the entry\'s `bumps` counter by 1 in the same edit '
          '(at >= $reGrandfatherBumpLimit bumps an open decomposition '
          'issue must be referenced, #3141).\n'
          '${grownFiles.join("\n")}',
    );

    // Shrink ratchet (#1680): a grandfathered file decomposed below the
    // limit must be removed from the snapshot map so the debt baseline
    // stays honest.
    final staleBaseline = grandfatheredSnapshot.keys.toSet().difference(
      stillOver,
    );
    expect(
      staleBaseline,
      isEmpty,
      reason:
          'These files are no longer over $lineLimit lines — remove '
          'them from the `grandfatheredSnapshot` map in this test so '
          'the debt baseline stays honest:\n${staleBaseline.join("\n")}',
    );
  });

  test('anti-re-grandfathering ratchet (#3141): '
      '>= $reGrandfatherBumpLimit snapshot bumps require an open '
      'decomposition issue', () {
    // Repeatedly re-grandfathering a file upward is how god files grow
    // forever via "justified +N" bumps. Once a file has accumulated
    // [reGrandfatherBumpLimit] bumps, its entry must reference the OPEN
    // GitHub issue that tracks decomposing it (and that issue must stay
    // open until the file graduates below the cap).
    final missingIssue = <String>[];
    final invalidIssue = <String>[];
    for (final MapEntry(key: path, value: snap)
        in grandfatheredSnapshot.entries) {
      final issue = snap.decompositionIssue;
      if (issue != null && issue <= 0) {
        invalidIssue.add('$path  (decompositionIssue: $issue)');
      }
      if (snap.bumps >= reGrandfatherBumpLimit && issue == null) {
        missingIssue.add('$path  (${snap.bumps} bumps, no issue)');
      }
    }

    expect(
      invalidIssue,
      isEmpty,
      reason:
          'decompositionIssue must be a real GitHub issue number:\n'
          '${invalidIssue.join("\n")}',
    );

    expect(
      missingIssue,
      isEmpty,
      reason:
          'These grandfathered files have been re-grandfathered upward '
          '$reGrandfatherBumpLimit+ times without an open decomposition '
          'issue. File a decomposition issue for each file (what to '
          'extract, along which seams, done = under the '
          '$lineLimit-line cap) and record its number as '
          '`decompositionIssue:` on the snapshot entry — the bump '
          'pattern stops here (#3141):\n${missingIssue.join("\n")}',
    );
  });
}
