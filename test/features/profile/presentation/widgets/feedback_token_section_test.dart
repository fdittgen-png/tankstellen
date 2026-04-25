import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter_provider.dart';
import 'package:tankstellen/features/profile/presentation/widgets/feedback_token_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [FeedbackTokenSection] (#952 phase 3).
///
/// Storage is intercepted via the `TestFlutterSecureStoragePlatform`
/// test seam ships with `flutter_secure_storage` 10.x — no method
/// channel mocking required.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> store;

  setUp(() {
    store = <String, String>{};
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(store);
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    Map<String, String>? seed,
  }) async {
    if (seed != null) store.addAll(seed);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FeedbackTokenSection()),
        ),
      ),
    );
    // Allow the initial async secure-storage read to complete.
    await tester.pumpAndSettle();
  }

  testWidgets('renders "No token" status when storage is empty',
      (tester) async {
    await pumpSection(tester);
    expect(find.text('No token'), findsOneWidget);
    expect(find.text('Set'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('renders "Token configured" when storage is seeded',
      (tester) async {
    await pumpSection(tester, seed: {kGithubFeedbackTokenKey: 'ghp_xyz'});
    expect(find.text('Token configured'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('Set writes the typed token to FlutterSecureStorage',
      (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  ghp_typed_in  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Whitespace is scrubbed.
    expect(store[kGithubFeedbackTokenKey], 'ghp_typed_in');
    expect(find.text('Token configured'), findsOneWidget);
  });

  testWidgets('Clear deletes the stored token', (tester) async {
    await pumpSection(tester, seed: {kGithubFeedbackTokenKey: 'ghp_existing'});
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(store.containsKey(kGithubFeedbackTokenKey), isFalse);
    expect(find.text('No token'), findsOneWidget);
  });

  testWidgets('empty / whitespace-only input is rejected (no write)',
      (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.containsKey(kGithubFeedbackTokenKey), isFalse);
    expect(find.text('No token'), findsOneWidget);
  });

  testWidgets('cancel on the dialog does not write anything', (tester) async {
    await pumpSection(tester);
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ghp_should_not_save');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(store.containsKey(kGithubFeedbackTokenKey), isFalse);
  });
}
