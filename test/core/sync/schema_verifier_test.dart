import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';

void main() {
  group('SchemaVerifier - table lists', () {
    test('requiredTables contains exactly 6 expected tables', () {
      expect(SchemaVerifier.requiredTables, hasLength(6));
      expect(SchemaVerifier.requiredTables, containsAll([
        'users',
        'favorites',
        'alerts',
        'price_snapshots',
        'push_tokens',
        'sync_settings',
      ]));
    });

    test('optionalTables contains exactly 4 expected tables', () {
      expect(SchemaVerifier.optionalTables, hasLength(4));
      expect(SchemaVerifier.optionalTables, containsAll([
        'price_reports',
        'itineraries',
        'ignored_stations',
        'station_ratings',
      ]));
    });
  });

  group('SchemaVerifier.getMigrationSql', () {
    test('returns only RLS SQL when all tables exist', () {
      final schema = <String, bool>{
        'users': true,
        'favorites': true,
        'alerts': true,
        'price_snapshots': true,
        'push_tokens': true,
        'sync_settings': true,
        'price_reports': true,
        'itineraries': true,
        'ignored_stations': true,
        'station_ratings': true,
      };

      final sql = SchemaVerifier.getMigrationSql(schema);

      // Should not contain CREATE TABLE for existing tables
      expect(sql, isNot(contains('CREATE TABLE IF NOT EXISTS users')));
      expect(sql, isNot(contains('CREATE TABLE IF NOT EXISTS favorites')));
      // Should still contain RLS policies
      expect(sql.toLowerCase(), contains('rls'));
    });

    test('includes CREATE TABLE for missing users table', () {
      final schema = <String, bool>{
        'users': false,
        'favorites': true,
        'alerts': true,
        'price_snapshots': true,
        'push_tokens': true,
        'sync_settings': true,
      };

      final sql = SchemaVerifier.getMigrationSql(schema);

      expect(sql, contains('CREATE TABLE IF NOT EXISTS'));
      expect(sql, contains('users'));
    });

    test('includes CREATE TABLE for all missing tables', () {
      final schema = <String, bool>{
        'users': false,
        'favorites': false,
        'alerts': false,
        'price_snapshots': true,
        'push_tokens': true,
        'sync_settings': true,
      };

      final sql = SchemaVerifier.getMigrationSql(schema);

      expect(sql, contains('users'));
      expect(sql, contains('favorites'));
      expect(sql, contains('alerts'));
      // Existing tables should not get CREATE statements
      expect(sql, isNot(contains('CREATE TABLE IF NOT EXISTS price_snapshots')));
    });

    test('always includes RLS policies in output', () {
      // All tables present
      final schemaAllPresent = <String, bool>{
        'users': true,
        'favorites': true,
        'alerts': true,
        'price_snapshots': true,
        'push_tokens': true,
        'sync_settings': true,
      };

      final sqlAllPresent = SchemaVerifier.getMigrationSql(schemaAllPresent);
      expect(sqlAllPresent.toLowerCase(), contains('rls'));

      // Some tables missing
      final schemaMissing = <String, bool>{
        'users': false,
        'favorites': true,
        'alerts': true,
        'price_snapshots': true,
        'push_tokens': true,
        'sync_settings': true,
      };

      final sqlMissing = SchemaVerifier.getMigrationSql(schemaMissing);
      expect(sqlMissing.toLowerCase(), contains('rls'));
    });

    test('SQL output uses CREATE TABLE IF NOT EXISTS syntax', () {
      final schema = <String, bool>{
        'users': false,
        'favorites': false,
        'alerts': true,
        'price_snapshots': true,
        'push_tokens': true,
        'sync_settings': true,
      };

      final sql = SchemaVerifier.getMigrationSql(schema);

      // Verify proper CREATE TABLE IF NOT EXISTS syntax
      expect(sql, contains('CREATE TABLE IF NOT EXISTS'));
    });

    test('handles empty schema map gracefully', () {
      final schema = <String, bool>{};

      // Should not throw
      final sql = SchemaVerifier.getMigrationSql(schema);
      expect(sql, isA<String>());
    });
  });
}
