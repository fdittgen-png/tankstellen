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
    // _SaveDeleteActions was extracted to a `part of` file via #563, so the
    // library source is split across two files. Read both and concat so the
    // regression checks see the full wiring.
    String readLibrarySource() {
      final main = File(
        'lib/features/profile/presentation/widgets/profile_edit_sheet.dart',
      ).readAsStringSync();
      final parts = File(
        'lib/features/profile/presentation/widgets/profile_edit_sheet_parts.dart',
      ).readAsStringSync();
      return '$main\n$parts';
    }

    test('delete button routes through _confirmDelete, not onDelete directly', () {
      final source = readLibrarySource();

      // The delete button lives in the extracted _SaveDeleteActions widget
      // and fires an onConfirmDelete callback, which the parent wires to
      // the _confirmDelete method. Both ends of the wiring must be present.
      expect(
        source.contains('onConfirmDelete: () => _confirmDelete(context)'),
        isTrue,
        reason:
            'Parent must wire onConfirmDelete to _confirmDelete (not onDelete)',
      );
      expect(
        source.contains('onPressed: onConfirmDelete'),
        isTrue,
        reason: 'Delete button must invoke the onConfirmDelete callback',
      );

      // Must NOT call onDelete directly from the delete button's onPressed.
      expect(
        RegExp(r'onPressed:\s*\(\)\s*\{\s*widget\.onDelete!\(\)')
            .hasMatch(source),
        isFalse,
        reason:
            'Delete button must NOT call widget.onDelete! directly from onPressed',
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

      // The _confirmDelete method must early-out when the user dismisses
      // the dialog and only invoke onDelete when confirmed.
      // Phrased as a regex so the exact comparison style (==/!=) and any
      // surrounding mounted check don't lock us into one implementation.
      expect(source, matches(RegExp(r'confirmed\s*(==|!=)\s*true')));
      expect(source, contains('widget.onDelete!()'));
    });
  });
}
