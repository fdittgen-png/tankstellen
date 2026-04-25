import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/presentation/widgets/location_section_widget.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

/// Active-profile notifier returning a fixed value.
class _FixedActiveProfile extends ActiveProfile {
  _FixedActiveProfile(this._value);
  final UserProfile? _value;

  @override
  UserProfile? build() => _value;
}

/// AutoSwitchProfile notifier that records `set()` calls.
class _RecordingAutoSwitch extends AutoSwitchProfile {
  _RecordingAutoSwitch(this._initial);
  final bool _initial;
  final List<bool> setCalls = [];

  @override
  bool build() => _initial;

  @override
  Future<void> set(bool value) async {
    setCalls.add(value);
    state = value;
  }
}

/// UserPosition notifier returning a fixed value and recording calls.
///
/// Overrides `clear()` and `updateFromGps()` so the widget tests do not
/// reach into the real storage / location service.
class _FakeUserPosition extends UserPosition {
  _FakeUserPosition({this.initial, this.throwOnUpdate = false});
  final UserPositionData? initial;
  final bool throwOnUpdate;
  int clearCount = 0;
  int updateCount = 0;

  @override
  UserPositionData? build() => initial;

  @override
  void clear() {
    clearCount++;
    state = null;
  }

  @override
  Future<void> updateFromGps() async {
    updateCount++;
    if (throwOnUpdate) {
      throw Exception('Location permission denied.');
    }
  }
}

UserProfile _profile({bool autoUpdate = false}) => UserProfile(
      id: 'p1',
      name: 'Standard',
      preferredFuelType: FuelType.e10,
      countryCode: 'de',
      autoUpdatePosition: autoUpdate,
    );

/// Builds the override list shared by every test. Storage and country
/// overrides come from `standardTestOverrides()`; profile, position, and
/// auto-switch are injected per-test.
({
  List<Object> overrides,
  MockProfileRepository repo,
  _FakeUserPosition position,
  _RecordingAutoSwitch autoSwitch,
}) _buildOverrides({
  UserProfile? profile,
  UserPositionData? position,
  bool autoSwitch = false,
  bool gpsThrows = false,
}) {
  final std = standardTestOverrides();
  final repo = MockProfileRepository();
  final fakePos = _FakeUserPosition(
    initial: position,
    throwOnUpdate: gpsThrows,
  );
  final fakeSwitch = _RecordingAutoSwitch(autoSwitch);

  return (
    overrides: [
      ...std.overrides,
      profileRepositoryProvider.overrideWithValue(repo),
      activeProfileProvider.overrideWith(() => _FixedActiveProfile(profile)),
      userPositionProvider.overrideWith(() => fakePos),
      autoSwitchProfileProvider.overrideWith(() => fakeSwitch),
    ],
    repo: repo,
    position: fakePos,
    autoSwitch: fakeSwitch,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_profile());
  });

  group('LocationSectionWidget', () {
    testWidgets('shows tap-to-update prompt when GPS is unset',
        (tester) async {
      final ctx = _buildOverrides(profile: _profile());

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      expect(find.text('Tap to update GPS position'), findsOneWidget);
      // No "Clear" delete button when no position is stored.
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      // The hint text is rendered below the tappable area.
      expect(
        find.textContaining('GPS position is acquired automatically'),
        findsOneWidget,
      );
    });

    testWidgets('shows source + age and delete button when GPS is set',
        (tester) async {
      final ctx = _buildOverrides(
        profile: _profile(),
        position: UserPositionData(
          lat: 48.0,
          lng: 11.0,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          source: 'GPS',
        ),
      );

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      expect(find.textContaining('GPS'), findsAtLeast(1));
      expect(find.textContaining('min'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Tap to update GPS position'), findsNothing);
    });

    testWidgets('age formatting renders hours when < 24h', (tester) async {
      final ctx = _buildOverrides(
        profile: _profile(),
        position: UserPositionData(
          lat: 48.0,
          lng: 11.0,
          // Add a small buffer so frame jitter cannot drop us under 3h.
          updatedAt: DateTime.now()
              .subtract(const Duration(hours: 3, minutes: 1)),
          source: 'GPS',
        ),
      );

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      // Hours branch must surface "h" and not collapse to "min" / "d".
      expect(find.textContaining('GPS (3 h)'), findsOneWidget);
    });

    testWidgets('age formatting renders days when ≥ 24h', (tester) async {
      final ctx = _buildOverrides(
        profile: _profile(),
        position: UserPositionData(
          lat: 48.0,
          lng: 11.0,
          // Use ~2 days + buffer so test elapsed time can't push
          // `inDays` from 2 down to 1 mid-frame.
          updatedAt: DateTime.now()
              .subtract(const Duration(days: 2, hours: 2)),
          source: 'GPS',
        ),
      );

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      expect(find.textContaining('GPS (2 d)'), findsOneWidget);
    });

    testWidgets('tap delete → confirm dialog → "Clear" calls notifier.clear',
        (tester) async {
      final ctx = _buildOverrides(
        profile: _profile(),
        position: UserPositionData(
          lat: 48.0,
          lng: 11.0,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
          source: 'GPS',
        ),
      );

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Dialog visible with Cancel + Delete buttons.
      expect(find.text('Cancel'), findsOneWidget);
      // 'Delete' appears twice: dialog title + filled-button label
      // (both bound to AppLocalizations.delete).
      expect(find.text('Delete'), findsNWidgets(2));

      // Tap the FilledButton (the action), not the title text.
      await tester.tap(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(ctx.position.clearCount, 1);
    });

    testWidgets('tap delete → "Cancel" leaves the position untouched',
        (tester) async {
      final ctx = _buildOverrides(
        profile: _profile(),
        position: UserPositionData(
          lat: 48.0,
          lng: 11.0,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
          source: 'GPS',
        ),
      );

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(ctx.position.clearCount, 0);
    });

    testWidgets('tap-to-update calls userPositionProvider.updateFromGps',
        (tester) async {
      final ctx = _buildOverrides(profile: _profile());

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      await tester.tap(find.text('Tap to update GPS position'));
      await tester.pumpAndSettle();

      expect(ctx.position.updateCount, 1);
    });

    testWidgets('tap-to-update error → shows GPS error SnackBar',
        (tester) async {
      final ctx = _buildOverrides(profile: _profile(), gpsThrows: true);

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      await tester.tap(find.text('Tap to update GPS position'));
      // pumpAndSettle would wait for the SnackBar to vanish; pump a few
      // frames instead so we can assert it is currently visible.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(ctx.position.updateCount, 1);
      expect(find.textContaining('GPS error'), findsOneWidget);
    });

    testWidgets('auto-update toggle reflects active profile + persists changes',
        (tester) async {
      final ctx = _buildOverrides(profile: _profile(autoUpdate: false));
      when(() => ctx.repo.updateProfile(any())).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      // Title rendered.
      expect(find.text('Auto-update position'), findsOneWidget);

      final autoUpdateSwitch = find.ancestor(
        of: find.text('Auto-update position'),
        matching: find.byType(SwitchListTile),
      );
      expect(autoUpdateSwitch, findsOneWidget);
      // Initial state = off.
      expect(
        tester.widget<SwitchListTile>(autoUpdateSwitch).value,
        isFalse,
      );

      await tester.tap(autoUpdateSwitch);
      await tester.pumpAndSettle();

      final captured = verify(() => ctx.repo.updateProfile(captureAny()))
          .captured
          .single as UserProfile;
      expect(captured.autoUpdatePosition, isTrue);
    });

    testWidgets('auto-switch toggle reflects provider + records set() call',
        (tester) async {
      final ctx = _buildOverrides(
        profile: _profile(),
        autoSwitch: false,
      );

      await pumpApp(
        tester,
        const LocationSectionWidget(),
        overrides: ctx.overrides,
      );

      expect(find.text('Auto-switch profile'), findsOneWidget);

      final autoSwitchTile = find.ancestor(
        of: find.text('Auto-switch profile'),
        matching: find.byType(SwitchListTile),
      );
      expect(autoSwitchTile, findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(autoSwitchTile).value,
        isFalse,
      );

      await tester.tap(autoSwitchTile);
      await tester.pumpAndSettle();

      expect(ctx.autoSwitch.setCalls, [true]);
    });
  });
}
