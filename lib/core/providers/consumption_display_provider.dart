// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/consumption_unit.dart';
import '../utils/price_formatter.dart';

part 'consumption_display_provider.g.dart';

/// How consumption figures are displayed (#3883, Epic #3881): the unit
/// (app-wide) and the rolling window of the live "last N s" figure.
@immutable
class ConsumptionDisplay {
  const ConsumptionDisplay({
    this.unitOverride,
    this.windowSeconds = kDefaultLiveConsumptionWindowSeconds,
  });

  /// The user's explicit unit, or null for "automatic" (the active
  /// country's convention — mpg in GB/US, L/100 km elsewhere).
  final ConsumptionUnit? unitOverride;

  /// Length of the live rolling-average window, one of
  /// [kLiveConsumptionWindowChoices].
  final int windowSeconds;

  /// The unit every consumption surface renders in.
  ConsumptionUnit get unit =>
      unitOverride ?? ConsumptionUnit.defaultFor(PriceFormatter.activeCountry);

  Duration get window => Duration(seconds: windowSeconds);

  ConsumptionDisplay copyWith({
    ConsumptionUnit? unitOverride,
    bool clearUnitOverride = false,
    int? windowSeconds,
  }) =>
      ConsumptionDisplay(
        unitOverride:
            clearUnitOverride ? null : (unitOverride ?? this.unitOverride),
        windowSeconds: windowSeconds ?? this.windowSeconds,
      );
}

/// The default rolling window — 5 s, as asked: long enough to stop the
/// figure jittering with injector batching, short enough to answer to
/// the pedal.
const int kDefaultLiveConsumptionWindowSeconds = 5;

/// The window lengths offered in Settings. The controller buffers 30 s,
/// so nothing longer can be offered without raising that.
const List<int> kLiveConsumptionWindowChoices = [3, 5, 10, 30];

/// Persisted consumption-display preference (#3883). Device-local like
/// the theme choice, so it lives in SharedPreferences and is readable
/// before any Hive box opens.
@Riverpod(keepAlive: true)
class ConsumptionDisplaySetting extends _$ConsumptionDisplaySetting {
  static const _unitKey = 'settings.consumptionUnit';
  static const _windowKey = 'settings.liveConsumptionWindowSeconds';

  @override
  ConsumptionDisplay build() {
    unawaited(_load());
    return const ConsumptionDisplay();
  }

  Future<void> _load() async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return; // no plugin (widget tests) — the defaults stand
    }
    final unit = ConsumptionUnit.parse(prefs.getString(_unitKey));
    final window = prefs.getInt(_windowKey);
    final restored = ConsumptionDisplay(
      unitOverride: unit,
      windowSeconds: window != null && kLiveConsumptionWindowChoices.contains(window)
          ? window
          : kDefaultLiveConsumptionWindowSeconds,
    );
    if (restored.unitOverride != state.unitOverride ||
        restored.windowSeconds != state.windowSeconds) {
      state = restored;
    }
  }

  /// Pick an explicit unit, or `null` to follow the country convention.
  Future<void> setUnit(ConsumptionUnit? unit) async {
    state = state.copyWith(unitOverride: unit, clearUnitOverride: unit == null);
    final prefs = await SharedPreferences.getInstance();
    if (unit == null) {
      await prefs.remove(_unitKey);
    } else {
      await prefs.setString(_unitKey, unit.wireName);
    }
  }

  Future<void> setWindowSeconds(int seconds) async {
    if (!kLiveConsumptionWindowChoices.contains(seconds)) return;
    state = state.copyWith(windowSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_windowKey, seconds);
  }
}
