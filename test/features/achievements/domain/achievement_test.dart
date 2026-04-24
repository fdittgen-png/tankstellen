import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/achievements/domain/achievement.dart';

void main() {
  group('EarnedAchievement.toJson', () {
    final ts = DateTime.utc(2026, 4, 24, 10, 30, 0);

    for (final id in AchievementId.values) {
      test('encodes ${id.name} with iso timestamp', () {
        final earned = EarnedAchievement(id: id, earnedAt: ts);
        final json = earned.toJson();
        expect(json['id'], id.name);
        expect(json['earnedAt'], ts.toIso8601String());
      });
    }
  });

  group('EarnedAchievement.fromJson — roundtrip per id', () {
    final ts = DateTime.utc(2026, 4, 24, 10, 30, 0);

    for (final id in AchievementId.values) {
      test('${id.name} survives toJson→fromJson', () {
        final original = EarnedAchievement(id: id, earnedAt: ts);
        final restored = EarnedAchievement.fromJson(original.toJson());
        expect(restored, isNotNull);
        expect(restored!.id, id);
        expect(restored.earnedAt, ts);
      });
    }
  });

  group('EarnedAchievement.fromJson — null / malformed branches', () {
    test('returns null when id is missing', () {
      final result = EarnedAchievement.fromJson({
        'earnedAt': DateTime.utc(2026, 4, 24).toIso8601String(),
      });
      expect(result, isNull);
    });

    test('returns null when id is explicitly null', () {
      final result = EarnedAchievement.fromJson({
        'id': null,
        'earnedAt': DateTime.utc(2026, 4, 24).toIso8601String(),
      });
      expect(result, isNull);
    });

    test('returns null when earnedAt is missing', () {
      final result = EarnedAchievement.fromJson({
        'id': AchievementId.firstTrip.name,
      });
      expect(result, isNull);
    });

    test('returns null when earnedAt is explicitly null', () {
      final result = EarnedAchievement.fromJson({
        'id': AchievementId.firstTrip.name,
        'earnedAt': null,
      });
      expect(result, isNull);
    });

    test('returns null when id name is unknown', () {
      final result = EarnedAchievement.fromJson({
        'id': 'unknown',
        'earnedAt': DateTime.utc(2026, 4, 24).toIso8601String(),
      });
      expect(result, isNull);
    });

    test('returns null when earnedAt is not parseable (catch branch)', () {
      final result = EarnedAchievement.fromJson({
        'id': AchievementId.firstTrip.name,
        'earnedAt': 'not-a-date',
      });
      expect(result, isNull);
    });

    test('returns populated EarnedAchievement for valid id + valid iso', () {
      final iso = DateTime.utc(2026, 1, 2, 3, 4, 5).toIso8601String();
      final result = EarnedAchievement.fromJson({
        'id': AchievementId.priceWin.name,
        'earnedAt': iso,
      });
      expect(result, isNotNull);
      expect(result!.id, AchievementId.priceWin);
      expect(result.earnedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });
  });
}
