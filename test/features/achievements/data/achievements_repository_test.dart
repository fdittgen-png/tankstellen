import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/achievements/data/achievements_repository.dart';
import 'package:tankstellen/features/achievements/domain/achievement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('achievements_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<String>(
      'test_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('AchievementsRepository (#781)', () {
    test('empty box returns empty list', () {
      final repo = AchievementsRepository(box: box);
      expect(repo.loadAll(), isEmpty);
    });

    test('mergeEarned persists new ids and reports them as fresh',
        () async {
      final repo = AchievementsRepository(box: box);
      final now = DateTime(2026, 1, 1, 12);
      final fresh = await repo.mergeEarned(
        {AchievementId.firstTrip, AchievementId.firstFillUp},
        now: now,
      );
      expect(fresh, hasLength(2));
      expect(repo.loadAll(), hasLength(2));
    });

    test('mergeEarned preserves the original earnedAt — re-earning '
        'the same badge later returns nothing fresh and keeps the '
        'first timestamp', () async {
      final repo = AchievementsRepository(box: box);
      final first = DateTime(2026, 1, 1);
      await repo.mergeEarned({AchievementId.firstTrip}, now: first);

      final second = DateTime(2026, 2, 1);
      final freshSecond = await repo.mergeEarned(
        {AchievementId.firstTrip},
        now: second,
      );
      expect(freshSecond, isEmpty);

      final stored = repo.loadAll();
      expect(stored, hasLength(1));
      expect(stored.first.earnedAt, first);
    });

    test('loadAll sorts newest-first', () async {
      final repo = AchievementsRepository(box: box);
      await repo.mergeEarned(
        {AchievementId.firstTrip},
        now: DateTime(2026, 1, 1),
      );
      await repo.mergeEarned(
        {AchievementId.firstFillUp},
        now: DateTime(2026, 2, 1),
      );
      final all = repo.loadAll();
      expect(all.first.id, AchievementId.firstFillUp);
      expect(all.last.id, AchievementId.firstTrip);
    });

    test('corrupt payload is skipped', () async {
      await box.put('garbage', 'not JSON');
      final repo = AchievementsRepository(box: box);
      await repo.mergeEarned(
        {AchievementId.firstTrip},
        now: DateTime(2026, 1, 1),
      );
      final all = repo.loadAll();
      expect(all, hasLength(1));
      expect(all.first.id, AchievementId.firstTrip);
    });

    test('clear wipes the box', () async {
      final repo = AchievementsRepository(box: box);
      await repo.mergeEarned(
        {AchievementId.firstTrip, AchievementId.firstFillUp},
        now: DateTime(2026, 1, 1),
      );
      await repo.clear();
      expect(repo.loadAll(), isEmpty);
    });
  });
}
