import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/services/location_search_service.dart';

class MockDio extends Mock implements Dio {}

/// Mocktail mock of [HiveStorage].
///
/// Prefer [`FakeHiveStorage`](../fakes/fake_hive_storage.dart) for any test
/// that exercises real storage state transitions (write-then-read, batch
/// updates, listener-on-change). A mocktail mock of a stateful repository
/// does not track state changes — `when(s.read('x')).thenReturn('y')` does
/// not update when production code calls `s.write('x', 'z')`. See
/// `feedback_test_doubles_must_mirror_real_service_outputs.md` for the
/// rationale; remaining usages are widget-rendering tests where pure
/// stub-out is acceptable.
@Deprecated(
  'Use FakeHiveStorage from test/fakes/fake_hive_storage.dart for stateful '
  'tests. Mocks remain only for widget tests that stub reads exclusively.',
)
class MockHiveStorage extends Mock implements HiveStorage {}

/// Mocktail mock of [StorageRepository].
///
/// Prefer [`FakeStorageRepository`](../fakes/fake_storage_repository.dart)
/// for any test that exercises real storage state transitions. See
/// [MockHiveStorage] for the rationale.
@Deprecated(
  'Use FakeStorageRepository from test/fakes/fake_storage_repository.dart '
  'for stateful tests. Mocks remain only for widget tests that stub reads '
  'exclusively.',
)
class MockStorageRepository extends Mock implements StorageRepository {}

class MockCacheManager extends Mock implements CacheManager {}
class MockStationService extends Mock implements StationService {}
class MockLocationSearchService extends Mock implements LocationSearchService {}
