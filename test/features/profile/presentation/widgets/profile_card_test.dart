import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/presentation/widgets/profile_list_section.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

final _testProfile = const UserProfile(
  id: 'profile-1',
  name: 'Home',
  preferredFuelType: FuelType.e10,
  defaultSearchRadius: 10.0,
  landingScreen: LandingScreen.search,
  countryCode: 'DE',
);

final _testProfile2 = const UserProfile(
  id: 'profile-2',
  name: 'Work',
  preferredFuelType: FuelType.diesel,
  defaultSearchRadius: 15.0,
  landingScreen: LandingScreen.favorites,
  countryCode: 'DE',
);

void main() {
  late MockProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockProfileRepository();
  });

  group('ProfileListSection card', () {
    testWidgets('renders profile name', (tester) async {
      when(() => mockRepo.getActiveProfile()).thenReturn(_testProfile);
      when(() => mockRepo.getAllProfiles()).thenReturn([_testProfile]);

      final std = standardTestOverrides();

      await pumpApp(
        tester,
        const ProfileListSection(),
        overrides: [
          ...std.overrides,
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows active indicator for active profile', (tester) async {
      when(() => mockRepo.getActiveProfile()).thenReturn(_testProfile);
      when(() => mockRepo.getAllProfiles()).thenReturn([_testProfile]);

      final std = standardTestOverrides();

      await pumpApp(
        tester,
        const ProfileListSection(),
        overrides: [
          ...std.overrides,
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      // Active profile uses person (filled) icon, not person_outline.
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsNothing);
      // No Aktivieren button for the active profile.
      expect(find.text('Aktivieren'), findsNothing);
    });

    testWidgets('shows Aktivieren button for inactive profile',
        (tester) async {
      // profile-1 is active, profile-2 is inactive
      when(() => mockRepo.getActiveProfile()).thenReturn(_testProfile);
      when(() => mockRepo.getAllProfiles())
          .thenReturn([_testProfile, _testProfile2]);

      final std = standardTestOverrides();

      await pumpApp(
        tester,
        const ProfileListSection(),
        overrides: [
          ...std.overrides,
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      // The inactive profile should show an Aktivieren button.
      expect(find.text('Aktivieren'), findsOneWidget);
      // The inactive profile uses person_outline icon.
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });
}
