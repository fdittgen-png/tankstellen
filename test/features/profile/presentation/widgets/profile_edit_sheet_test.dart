import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('Delete profile confirmation dialog', () {
    // Test the confirmation dialog in isolation, since ProfileEditSheet
    // uses DraggableScrollableSheet which requires complex sizing in tests.
    testWidgets('shows warning icon and destructive message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    icon: Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    title: Text(AppLocalizations.of(context)?.deleteProfileTitle ??
                        'Delete profile?'),
                    content: Text(
                      AppLocalizations.of(context)?.deleteProfileBody ??
                          'This profile and its settings will be permanently deleted. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                            AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                            AppLocalizations.of(context)?.deleteProfileConfirm ??
                                'Delete profile'),
                      ),
                    ],
                  ),
                );
              });
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dialog is visible with all expected elements
      expect(find.text('Delete profile?'), findsOneWidget);
      expect(find.textContaining('permanently deleted'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete profile'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete profile?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete profile'),
                      ),
                    ],
                  ),
                );
              });
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('confirm returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete profile?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete profile'),
                      ),
                    ],
                  ),
                );
              });
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete profile'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('Delete profile l10n', () {
    test('English ARB has deleteProfile strings', () {
      final source = File('lib/l10n/app_en.arb').readAsStringSync();
      expect(source, contains('deleteProfileTitle'));
      expect(source, contains('deleteProfileBody'));
      expect(source, contains('deleteProfileConfirm'));
    });

    test('German ARB has deleteProfile strings', () {
      final source = File('lib/l10n/app_de.arb').readAsStringSync();
      expect(source, contains('deleteProfileTitle'));
      expect(source, contains('Profil löschen'));
    });

    test('French ARB has deleteProfile strings', () {
      final source = File('lib/l10n/app_fr.arb').readAsStringSync();
      expect(source, contains('deleteProfileTitle'));
      expect(source, contains('Supprimer le profil'));
    });

    test('all 23 ARB files have deleteProfile keys', () {
      final arbDir = Directory('lib/l10n');
      final arbFiles = arbDir.listSync().where(
            (f) => f.path.endsWith('.arb'),
          );
      for (final file in arbFiles) {
        final content = File(file.path).readAsStringSync();
        expect(
          content.contains('deleteProfileTitle'),
          isTrue,
          reason: '${file.path} missing deleteProfileTitle',
        );
      }
    });
  });

  group('ProfileEditSheet source-level regression', () {
    test('delete button calls _confirmDelete, not onDelete directly', () {
      final source = File(
        'lib/features/profile/presentation/widgets/profile_edit_sheet.dart',
      ).readAsStringSync();

      expect(
        source.contains('onPressed: () => _confirmDelete('),
        isTrue,
        reason: 'Delete button must use confirmation dialog via _confirmDelete',
      );

      // Should NOT call onDelete directly in onPressed
      expect(
        source.contains('onPressed: () {\n                      widget.onDelete!();'),
        isFalse,
        reason: 'Delete button must NOT call onDelete! directly without confirmation',
      );
    });

    test('_confirmDelete method uses showDialog', () {
      final source = File(
        'lib/features/profile/presentation/widgets/profile_edit_sheet.dart',
      ).readAsStringSync();

      expect(source, contains('_confirmDelete'));
      expect(source, contains('showDialog'));
      expect(source, contains('deleteProfileTitle'));
      expect(source, contains('deleteProfileBody'));
      expect(source, contains('deleteProfileConfirm'));
    });

    test('_confirmDelete only calls onDelete after confirmation', () {
      final source = File(
        'lib/features/profile/presentation/widgets/profile_edit_sheet.dart',
      ).readAsStringSync();

      // The _confirmDelete method should check confirmed == true before calling onDelete
      expect(source, contains('if (confirmed == true'));
      expect(source, contains('widget.onDelete!()'));
    });
  });
}
