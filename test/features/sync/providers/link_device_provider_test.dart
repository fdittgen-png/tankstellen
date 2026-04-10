import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/providers/link_device_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('LinkDeviceState', () {
    test('default is idle with no result', () {
      const s = LinkDeviceState();
      expect(s.isLinking, isFalse);
      expect(s.result, isNull);
      expect(s.isError, isFalse);
    });

    test('isError true when result starts with "Link failed"', () {
      const s = LinkDeviceState(result: 'Link failed: boom');
      expect(s.isError, isTrue);
    });

    test('isError false for success messages', () {
      const s = LinkDeviceState(result: 'Linked! Imported 2 favorites');
      expect(s.isError, isFalse);
    });

    test('copyWith preserves fields, clearResult wipes result', () {
      const s = LinkDeviceState(isLinking: true, result: 'boom');
      final cleared = s.copyWith(clearResult: true);
      expect(cleared.isLinking, isTrue);
      expect(cleared.result, isNull);
    });
  });

  group('LinkDeviceController', () {
    test('initial state is idle', () {
      final c = makeContainer();
      expect(c.read(linkDeviceControllerProvider).isLinking, isFalse);
      expect(c.read(linkDeviceControllerProvider).result, isNull);
    });

    test('linkDevice with empty code sets validation error', () async {
      final c = makeContainer();
      await c.read(linkDeviceControllerProvider.notifier).linkDevice('');
      final s = c.read(linkDeviceControllerProvider);
      expect(s.result, 'Please enter a valid device code');
      expect(s.isLinking, isFalse);
    });

    test('linkDevice with too-short code sets validation error', () async {
      final c = makeContainer();
      await c.read(linkDeviceControllerProvider.notifier).linkDevice('short');
      expect(
        c.read(linkDeviceControllerProvider).result,
        'Please enter a valid device code',
      );
    });
  });
}
