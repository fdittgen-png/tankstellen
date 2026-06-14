// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/providers/radar_scope_mode_provider.dart';

/// Pins the radar-scope view toggle (#3342): defaults to the list (false) and
/// flips on each `toggle()`.
void main() {
  test('defaults to the list (false) and toggles', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(radarScopeModeProvider), isFalse);
    container.read(radarScopeModeProvider.notifier).toggle();
    expect(container.read(radarScopeModeProvider), isTrue);
    container.read(radarScopeModeProvider.notifier).toggle();
    expect(container.read(radarScopeModeProvider), isFalse);
  });
}
