import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/ev/presentation/widgets/ev_filter_chips.dart';
import 'package:tankstellen/features/ev/providers/ev_providers.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('EvFilterChips toggles connector selection via provider',
      (tester) async {
    late ProviderContainer capturedContainer;

    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          capturedContainer = ProviderScope.containerOf(context);
          return const EvFilterChips();
        },
      ),
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(
          VehicleProfileRepository(_FakeSettings()),
        ),
      ],
    );

    expect(
      capturedContainer.read(evFilterControllerProvider).connectorTypes,
      isEmpty,
    );

    // Find the CCS chip and tap it.
    final ccsChip = find.widgetWithText(FilterChip, 'CCS');
    expect(ccsChip, findsOneWidget);
    await tester.ensureVisible(ccsChip);
    await tester.tap(ccsChip);
    await tester.pumpAndSettle();

    expect(
      capturedContainer
          .read(evFilterControllerProvider)
          .connectorTypes
          .contains(ConnectorType.ccs),
      isTrue,
    );
  });

  testWidgets('EvFilterChips exposes an "Available only" toggle',
      (tester) async {
    late ProviderContainer capturedContainer;

    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          capturedContainer = ProviderScope.containerOf(context);
          return const EvFilterChips();
        },
      ),
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(
          VehicleProfileRepository(_FakeSettings()),
        ),
      ],
    );

    final chip = find.widgetWithText(FilterChip, 'Available only');
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(
      capturedContainer.read(evFilterControllerProvider).availableOnly,
      isTrue,
    );
  });
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
