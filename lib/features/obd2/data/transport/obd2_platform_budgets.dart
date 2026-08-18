// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// #3172 — the single audited home for the platform-resolved BLE connect
/// budgets that were previously three inline `defaultTargetPlatform ==
/// TargetPlatform.iOS` forks scattered across the OBD2 stack
/// (`flutter_blue_plus_elm_channel.dart` ×2 + `obd2_connect_by_mac.dart`).
/// Pure consolidation: same values, same resolution rule, one place for the
/// next iOS timing fix to land.
///
/// Why iOS and Android differ AT ALL (each value is individually justified —
/// see the per-field docs): iOS CoreBluetooth is consistently slower than
/// Android's stack on the post-connect GATT steps, while Android's tight
/// bounds are LOAD-BEARING (#2242/#3014 — FBP would otherwise block
/// 15–35 s on a vanished/hung clone). Widening Android to match iOS would
/// reintroduce the SmartOBD freeze; tightening iOS clips the OBDLink CX.
///
/// NOT in here (different policy axes, documented for the auditor):
///  * the FIRST-connect pairing budget (30 s, platform-independent) —
///    [Obd2PairingMode.firstConnectSetNotifySecs] (#3181);
///  * the scan-path connect bound (10 s, platform-independent) —
///    `FlutterBluePlusElmChannel._scanPathConnectTimeout` (#2969).
@immutable
class Obd2PlatformBudgets {
  /// `discoverServices` budget in SECONDS (passed to FBP's own `timeout:`
  /// parameter, #3182). #3014 — bound on its own short budget (FBP default
  /// 15 s) so a clone whose GATT table never resolves fails fast as
  /// `gattTimeout`. #3118 — iOS CoreBluetooth's `discoverServices` is slower
  /// than Android's, so the OBDLink CX's GATT-table resolution can blow
  /// Android's tight 5 s on a cold iPhone connect.
  final int discoverTimeoutSecs;

  /// `setNotifyValue` (CCCD subscribe) budget in SECONDS (FBP `timeout:`,
  /// #3182). #3014 — a clone that accepts the descriptor write but never
  /// ACKs would otherwise block 15 s. #3118 — THIS was the OBDLink CX
  /// failure on iPhone: the post-connect CCCD write is slower over iOS
  /// CoreBluetooth than Android's 4 s. Android keeps the tight #2242/#3014
  /// load-bearing bound.
  final int setNotifyTimeoutSecs;

  /// Cold direct-by-MAC `connect()` budget (#2242). #3113 — a cold iOS
  /// CoreBluetooth GATT connect to an ELM clone (OBDLink CX) routinely
  /// exceeds Android's 4 s, so a live adapter was clipped mid-connect.
  /// Android's 4 s is LOAD-BEARING (#2242: `autoConnect:false` blocks
  /// ~35 s on a sleeping adapter, so the bound must stay tight there).
  final Duration directConnectTimeout;

  const Obd2PlatformBudgets._({
    required this.discoverTimeoutSecs,
    required this.setNotifyTimeoutSecs,
    required this.directConnectTimeout,
  });

  /// iOS CoreBluetooth budgets (#3113/#3118 — widened post-connect steps).
  static const Obd2PlatformBudgets ios = Obd2PlatformBudgets._(
    discoverTimeoutSecs: 8,
    setNotifyTimeoutSecs: 7,
    directConnectTimeout: Duration(seconds: 7),
  );

  /// Android budgets — byte-identical to the pre-#3113/#3118 values; the
  /// tight bounds are load-bearing (#2242/#3014).
  static const Obd2PlatformBudgets android = Obd2PlatformBudgets._(
    discoverTimeoutSecs: 5,
    setNotifyTimeoutSecs: 4,
    directConnectTimeout: Duration(seconds: 4),
  );

  /// The ONE platform fork (was three inline copies). Resolved via
  /// [defaultTargetPlatform] so the existing budget-pinning tests keep
  /// driving it through [debugDefaultTargetPlatformOverride]. Every
  /// non-iOS platform gets the Android budgets, exactly as before.
  static Obd2PlatformBudgets get resolved =>
      defaultTargetPlatform == TargetPlatform.iOS ? ios : android;

  /// #3421 — WHOLE-LADDER budget (ms) for the native Classic RFCOMM connect
  /// ladder (secure×3 → insecure → reflection channel-1 in
  /// `Obd2ClassicPlugin.kt`). The #3348 watchdog bounds each RUNG at 7 s but
  /// never the CALL: field trace t8 (#3415) shows ONE native connect blocking
  /// 16.8 minutes (t5: 4.7 min) on a half-open wedged channel. Dart threads
  /// this to the native `connect` as `budgetMs`; the Kotlin side skips the
  /// remaining rungs once it is spent and reports strategy `budget-exhausted`.
  /// Generous by design — a full healthy ladder (5 rungs × 7 s worst-case
  /// watchdog would exceed it, but a HEALTHY connect lands on rung 1–2 in
  /// ~1 s) — so it only bites when the ladder is genuinely wedged.
  /// Platform-independent (Classic SPP is Android-only). A plain `int` so it
  /// can serve as a const default parameter value on the channel binding.
  static const int classicConnectLadderBudgetMs = 20000;

  /// #3421 — Dart-side defense-in-depth grace on top of
  /// [classicConnectLadderBudgetMs]: `ClassicElmChannel.open` wraps the
  /// `connectDetailed` await in `.timeout(budget + grace)`, so even a WEDGED
  /// platform thread — whose Kotlin-side budget bookkeeping never runs
  /// because `BluetoothSocket.connect()` refuses to return — cannot hold a
  /// Dart caller for minutes. 3 s comfortably clears normal MethodChannel
  /// scheduling latency on top of the native budget.
  static const Duration classicConnectDartGrace = Duration(seconds: 3);
}
