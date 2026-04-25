import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/local_notification_service.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';

/// A fake [NotificationService] for testing that call sites work against
/// the abstract interface without touching platform channels.
class FakeNotificationService implements NotificationService {
  bool initialized = false;
  final List<({int id, String title, String body, String? payload})>
      shownAlerts = [];
  final List<({int id, String title, String body})> shownServiceReminders = [];
  final List<int> cancelledIds = [];
  bool allCancelled = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    shownAlerts.add((id: id, title: title, body: body, payload: payload));
  }

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    shownServiceReminders.add((id: id, title: title, body: body));
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    allCancelled = true;
  }
}

void main() {
  group('NotificationService interface', () {
    test('FakeNotificationService implements NotificationService', () {
      final service = FakeNotificationService();
      expect(service, isA<NotificationService>());
    });

    test('LocalNotificationService implements NotificationService', () {
      final service = LocalNotificationService();
      expect(service, isA<NotificationService>());
    });
  });

  group('FakeNotificationService', () {
    late FakeNotificationService service;

    setUp(() {
      service = FakeNotificationService();
    });

    test('initialize sets initialized flag', () async {
      expect(service.initialized, isFalse);
      await service.initialize();
      expect(service.initialized, isTrue);
    });

    test('showPriceAlert records notification', () async {
      await service.showPriceAlert(
        id: 42,
        title: 'Shell Station - E10',
        body: '1.459 \u20ac (target: 1.500 \u20ac)',
      );

      expect(service.shownAlerts, hasLength(1));
      expect(service.shownAlerts.first.id, 42);
      expect(service.shownAlerts.first.title, 'Shell Station - E10');
      expect(service.shownAlerts.first.body,
          '1.459 \u20ac (target: 1.500 \u20ac)');
    });

    test('showPriceAlert accumulates multiple notifications', () async {
      await service.showPriceAlert(id: 1, title: 'A', body: 'a');
      await service.showPriceAlert(id: 2, title: 'B', body: 'b');
      await service.showPriceAlert(id: 3, title: 'C', body: 'c');

      expect(service.shownAlerts, hasLength(3));
    });

    test('cancelNotification records cancelled id', () async {
      await service.cancelNotification(42);
      await service.cancelNotification(7);

      expect(service.cancelledIds, [42, 7]);
    });

    test('cancelAll sets flag', () async {
      expect(service.allCancelled, isFalse);
      await service.cancelAll();
      expect(service.allCancelled, isTrue);
    });

    test('can be used polymorphically via NotificationService type', () async {
      final NotificationService abstractRef = service;

      await abstractRef.initialize();
      await abstractRef.showPriceAlert(
        id: 99,
        title: 'Test',
        body: 'Body',
      );
      await abstractRef.cancelNotification(99);
      await abstractRef.cancelAll();

      expect(service.initialized, isTrue);
      expect(service.shownAlerts, hasLength(1));
      expect(service.cancelledIds, [99]);
      expect(service.allCancelled, isTrue);
    });
  });
}
