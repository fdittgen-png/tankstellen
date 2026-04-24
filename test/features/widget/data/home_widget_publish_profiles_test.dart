// Tests for HomeWidgetService.publishProfiles (#610).
//
// The configure activity (Kotlin side) reads a JSON array from the
// `widget_profiles_json` SharedPreferences key to populate its profile
// picker. This test captures the method-channel payload so we assert the
// exact shape the activity relies on (id, name, preferredFuel, currency)
// and that the list is complete.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Map<String, Object?> savedWidgetData;

  setUp(() {
    savedWidgetData = <String, Object?>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'saveWidgetData':
          final args = (call.arguments as Map).cast<String, Object?>();
          savedWidgetData[args['id']! as String] = args['data'];
          return true;
        case 'updateWidget':
          return true;
        case 'setAppGroupId':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('HomeWidgetService.publishProfiles (#610)', () {
    test('writes an empty JSON array when the profile list is empty',
        () async {
      await HomeWidgetService.publishProfiles(const []);

      final raw = savedWidgetData['widget_profiles_json'] as String?;
      expect(raw, isNotNull);
      expect(jsonDecode(raw!), isEmpty);
    });

    test('serialises every profile with id, name, preferredFuel, currency',
        () async {
      final profiles = <UserProfile>[
        const UserProfile(
          id: 'p1',
          name: 'Car',
          preferredFuelType: FuelType.e10,
          countryCode: 'DE',
        ),
        const UserProfile(
          id: 'p2',
          name: 'Truck',
          preferredFuelType: FuelType.diesel,
          countryCode: 'FR',
        ),
        const UserProfile(
          id: 'p3',
          name: 'Offroad',
          preferredFuelType: FuelType.e85,
        ),
      ];

      await HomeWidgetService.publishProfiles(profiles);

      final raw = savedWidgetData['widget_profiles_json'] as String?;
      expect(raw, isNotNull,
          reason: 'publishProfiles must write widget_profiles_json');
      final list = (jsonDecode(raw!) as List).cast<Map<String, dynamic>>();
      expect(list, hasLength(3));

      expect(list[0]['id'], 'p1');
      expect(list[0]['name'], 'Car');
      expect(list[0]['preferredFuel'], 'e10');
      expect(list[0]['currency'], '€',
          reason: 'DE profiles must publish the euro symbol');

      expect(list[1]['id'], 'p2');
      expect(list[1]['name'], 'Truck');
      expect(list[1]['preferredFuel'], 'diesel');
      expect(list[1]['currency'], '€',
          reason: 'FR is eurozone — currency must be €');

      expect(list[2]['id'], 'p3');
      expect(list[2]['name'], 'Offroad');
      expect(list[2]['preferredFuel'], 'e85');
      expect(list[2]['currency'], '',
          reason: 'profile without countryCode must publish empty currency, '
              'not null (Kotlin reads the key unconditionally)');
    });

    test('keeps order — activity radio list uses array index', () async {
      final profiles = <UserProfile>[
        for (var i = 0; i < 5; i++)
          UserProfile(
            id: 'id$i',
            name: 'Profile $i',
          ),
      ];

      await HomeWidgetService.publishProfiles(profiles);

      final list =
          (jsonDecode(savedWidgetData['widget_profiles_json']! as String)
                  as List)
              .cast<Map<String, dynamic>>();
      expect(
        list.map((p) => p['id']).toList(),
        ['id0', 'id1', 'id2', 'id3', 'id4'],
      );
    });
  });
}
