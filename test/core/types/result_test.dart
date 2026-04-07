import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/types/result.dart';

void main() {
  group('Success', () {
    test('isSuccess returns true', () {
      const result = Success<int, String>(42);
      expect(result.isSuccess, isTrue);
    });

    test('isFailure returns false', () {
      const result = Success<int, String>(42);
      expect(result.isFailure, isFalse);
    });

    test('valueOrNull returns the value', () {
      const result = Success<int, String>(42);
      expect(result.valueOrNull, 42);
    });

    test('errorOrNull returns null', () {
      const result = Success<int, String>(42);
      expect(result.errorOrNull, isNull);
    });

    test('valueOrThrow returns the value', () {
      const result = Success<int, String>(42);
      expect(result.valueOrThrow, 42);
    });

    test('toString includes the value', () {
      const result = Success<int, String>(42);
      expect(result.toString(), 'Success(42)');
    });

    test('equality works for same value', () {
      const a = Success<int, String>(42);
      const b = Success<int, String>(42);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different values', () {
      const a = Success<int, String>(42);
      const b = Success<int, String>(99);
      expect(a, isNot(equals(b)));
    });
  });

  group('Failure', () {
    test('isSuccess returns false', () {
      const result = Failure<int, String>('boom');
      expect(result.isSuccess, isFalse);
    });

    test('isFailure returns true', () {
      const result = Failure<int, String>('boom');
      expect(result.isFailure, isTrue);
    });

    test('valueOrNull returns null', () {
      const result = Failure<int, String>('boom');
      expect(result.valueOrNull, isNull);
    });

    test('errorOrNull returns the error', () {
      const result = Failure<int, String>('boom');
      expect(result.errorOrNull, 'boom');
    });

    test('valueOrThrow throws StateError', () {
      const result = Failure<int, String>('boom');
      expect(() => result.valueOrThrow, throwsStateError);
    });

    test('toString includes the error', () {
      const result = Failure<int, String>('boom');
      expect(result.toString(), 'Failure(boom)');
    });

    test('equality works for same error', () {
      const a = Failure<int, String>('boom');
      const b = Failure<int, String>('boom');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality for different errors', () {
      const a = Failure<int, String>('boom');
      const b = Failure<int, String>('crash');
      expect(a, isNot(equals(b)));
    });
  });

  group('map', () {
    test('transforms success value', () {
      const Result<int, String> result = Success(10);
      final mapped = result.map((v) => v * 2);
      expect(mapped.valueOrNull, 20);
      expect(mapped.isSuccess, isTrue);
    });

    test('passes through failure unchanged', () {
      const Result<int, String> result = Failure('error');
      final mapped = result.map((v) => v * 2);
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull, 'error');
    });
  });

  group('mapError', () {
    test('transforms failure error', () {
      const Result<int, String> result = Failure('error');
      final mapped = result.mapError((e) => e.length);
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull, 5);
    });

    test('passes through success unchanged', () {
      const Result<int, String> result = Success(42);
      final mapped = result.mapError((e) => e.length);
      expect(mapped.isSuccess, isTrue);
      expect(mapped.valueOrNull, 42);
    });
  });

  group('flatMap', () {
    test('chains successful operations', () {
      const Result<int, String> result = Success(10);
      final chained = result.flatMap((v) => Success(v.toString()));
      expect(chained.valueOrNull, '10');
    });

    test('short-circuits on initial failure', () {
      const Result<int, String> result = Failure('first error');
      final chained = result.flatMap((v) => Success(v.toString()));
      expect(chained.isFailure, isTrue);
      expect(chained.errorOrNull, 'first error');
    });

    test('propagates failure from chained operation', () {
      const Result<int, String> result = Success(10);
      final chained = result.flatMap<String>((_) => const Failure('chained error'));
      expect(chained.isFailure, isTrue);
      expect(chained.errorOrNull, 'chained error');
    });
  });

  group('fold', () {
    test('calls onSuccess for Success', () {
      const Result<int, String> result = Success(42);
      final folded = result.fold(
        onSuccess: (v) => 'got $v',
        onFailure: (e) => 'error: $e',
      );
      expect(folded, 'got 42');
    });

    test('calls onFailure for Failure', () {
      const Result<int, String> result = Failure('boom');
      final folded = result.fold(
        onSuccess: (v) => 'got $v',
        onFailure: (e) => 'error: $e',
      );
      expect(folded, 'error: boom');
    });
  });

  group('getOrElse', () {
    test('returns value for Success', () {
      const Result<int, String> result = Success(42);
      expect(result.getOrElse((_) => -1), 42);
    });

    test('returns fallback for Failure', () {
      const Result<int, String> result = Failure('boom');
      expect(result.getOrElse((e) => e.length), 4);
    });
  });

  group('pattern matching', () {
    test('exhaustive switch with sealed class', () {
      const Result<int, String> success = Success(1);
      const Result<int, String> failure = Failure('err');

      // This test verifies the sealed class enables exhaustive matching.
      // If it compiles without a default branch, the sealed contract works.
      String describe(Result<int, String> r) => switch (r) {
            Success(:final value) => 'ok: $value',
            Failure(:final error) => 'fail: $error',
          };

      expect(describe(success), 'ok: 1');
      expect(describe(failure), 'fail: err');
    });

    test('pattern matching with destructuring in if-case', () {
      const Result<int, String> result = Success(42);

      if (result case Success(:final value)) {
        expect(value, 42);
      } else {
        fail('Expected Success');
      }
    });
  });

  group('type safety', () {
    test('Success and Failure with complex types', () {
      final Result<List<int>, Exception> result = Success(const [1, 2, 3]);
      expect(result.valueOrNull, [1, 2, 3]);

      final Result<List<int>, Exception> failure =
          Failure(FormatException('bad'));
      expect(failure.errorOrNull, isA<FormatException>());
    });

    test('Result with void success type', () {
      const Result<void, String> result = Success(null);
      expect(result.isSuccess, isTrue);
    });
  });
}
