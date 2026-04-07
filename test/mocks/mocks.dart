import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/services/location_search_service.dart';

class MockDio extends Mock implements Dio {}
class MockHiveStorage extends Mock implements HiveStorage {}
class MockStorageRepository extends Mock implements StorageRepository {}
class MockCacheManager extends Mock implements CacheManager {}
class MockStationService extends Mock implements StationService {}
class MockLocationSearchService extends Mock implements LocationSearchService {}
