import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/loyalty/data/loyalty_card_repository.dart';
import 'package:tankstellen/features/loyalty/domain/entities/loyalty_card.dart';
import 'package:tankstellen/features/loyalty/presentation/loyalty_settings_screen.dart';
import 'package:tankstellen/features/loyalty/providers/loyalty_provider.dart';

import '../../../helpers/pump_app.dart';

/// In-memory fake repository so screen tests don't depend on a real
/// Hive box. Hive's Windows-file-backend has historically hung the
/// flutter_test fake-async zone (see `tearDownAll` lock errors in the
/// commit history) — the fake repository sidesteps the whole class
/// of issues and exercises the same notifier path.
class _FakeLoyaltyCardRepository implements LoyaltyCardRepository {
  final Map<String, LoyaltyCard> _store = <String, LoyaltyCard>{};

  @override
  List<LoyaltyCard> loadAll() {
    final out = _store.values.toList();
    out.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return out;
  }

  @override
  Future<void> upsert(LoyaltyCard card) async {
    _store[card.id] = card;
  }

  @override
  Future<void> remove(String id) async {
    _store.remove(id);
  }

  @override
  Future<LoyaltyCard?> setEnabled(String id, {required bool enabled}) async {
    final existing = _store[id];
    if (existing == null) return null;
    final updated = existing.copyWith(enabled: enabled);
    _store[id] = updated;
    return updated;
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

void main() {
  late _FakeLoyaltyCardRepository repo;

  setUp(() {
    repo = _FakeLoyaltyCardRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      const LoyaltySettingsScreen(),
      overrides: [
        loyaltyCardRepositoryProvider.overrideWith((ref) => repo),
      ],
    );
  }

  group('LoyaltySettingsScreen', () {
    testWidgets('renders the empty state when no card is registered',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('No fuel club cards yet'), findsOneWidget);
      // Both the empty-state CTA and the FAB expose "Add card".
      expect(find.text('Add card'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'tapping the Add card FAB opens the create sheet, '
        'submitting it persists a card', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add fuel club card'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Discount (per litre)'),
        '0.05',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Label (optional)'),
        'Personal',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('No fuel club cards yet'), findsNothing);
      expect(find.text('Personal'), findsOneWidget);
      // Persistence side: the fake repo holds the card.
      expect(repo.loadAll(), hasLength(1));
      expect(repo.loadAll().single.discountPerLiter, 0.05);
      expect(repo.loadAll().single.brand, LoyaltyBrand.totalEnergies);
    });

    testWidgets('Save is rejected when the discount field is empty',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a positive number'), findsOneWidget);
      // The sheet must still be open because Save short-circuited.
      expect(find.text('Add fuel club card'), findsOneWidget);
      // Nothing was persisted.
      expect(repo.loadAll(), isEmpty);
    });

    testWidgets(
        'tapping the trash icon shows a confirm dialog and deletes the card',
        (tester) async {
      // Pre-seed the fake so we can focus on the delete flow.
      await repo.upsert(LoyaltyCard(
        id: 'pre-seeded',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
        label: 'About-to-die',
        addedAt: DateTime(2026, 4, 1),
      ));

      await pumpScreen(tester);

      expect(find.text('About-to-die'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete card?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('About-to-die'), findsNothing);
      expect(find.text('No fuel club cards yet'), findsOneWidget);
      expect(repo.loadAll(), isEmpty);
    });

    testWidgets(
        'cancelling the confirm dialog keeps the card', (tester) async {
      await repo.upsert(LoyaltyCard(
        id: 'pre-seeded',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
        label: 'Sticking around',
        addedAt: DateTime(2026, 4, 1),
      ));

      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Sticking around'), findsOneWidget);
      expect(find.text('No fuel club cards yet'), findsNothing);
      expect(repo.loadAll(), hasLength(1));
    });

    testWidgets(
        'toggling the per-card switch flips the on-screen Switch state',
        (tester) async {
      await repo.upsert(LoyaltyCard(
        id: 'toggleable',
        brand: LoyaltyBrand.totalEnergies,
        discountPerLiter: 0.05,
        label: 'Toggleable',
        addedAt: DateTime(2026, 4, 1),
      ));

      await pumpScreen(tester);

      final switchFinder = find.byType(Switch).first;
      Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
      expect(repo.loadAll().single.enabled, isFalse);
    });
  });
}
