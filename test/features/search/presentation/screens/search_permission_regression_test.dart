// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

class _DeniedGeolocator extends GeolocatorWrapper {
  _DeniedGeolocator(this.permission);
  final LocationPermission permission;
  var fixRequests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    fixRequests++;
    throw StateError('a denied permission must not request a fix');
  }
}

void main() {
  setUp(() {
    errorLogger.spoolEnqueueOverride =
        ({
          required String isolateTaskName,
          required Object error,
          StackTrace? stack,
          Map<String, dynamic>? contextMap,
          DateTime? timestamp,
        }) async {};
  });
  tearDown(errorLogger.resetForTest);

  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
  ]) {
    testWidgets('#4514 refresh with $permission offers postcode search '
        'and retains the last valid position', (tester) async {
      tester.view.physicalSize = const Size(430, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.hasApiKey(any())).thenReturn(false);
      when(
        () => overrides.mockStorage.getSetting(StorageKeys.consentLocation),
      ).thenReturn(true);
      final geolocator = _DeniedGeolocator(permission);
      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...overrides.overrides,
          userPositionOverride(lat: 40.4187507, lng: -3.7070555),
          locationServiceProvider.overrideWithValue(
            LocationService(geolocator),
          ),
        ],
      );
      final context = tester.element(find.byType(SearchScreen));
      final container = ProviderScope.containerOf(context);
      final before = container.read(userPositionProvider);
      final l10n = AppLocalizations.of(context);
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.widgetWithIcon(IconButton, Icons.refresh),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.locationDenied), findsOneWidget);
      expect(find.text(l10n.searchFailedSnackbar), findsNothing);
      expect(container.read(userPositionProvider), same(before));
      expect(geolocator.fixRequests, 0);
    });
  }
}
