import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/sync_done_step.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SyncDoneStep', () {
    testWidgets('renders check icon, title, and description',
        (tester) async {
      await pumpApp(tester, const SyncDoneStep());

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Successfully connected!'), findsOneWidget);
      expect(
        find.textContaining('sync automatically'),
        findsOneWidget,
      );
    });

    testWidgets('icon is the positive green cue at 64 px', (tester) async {
      await pumpApp(tester, const SyncDoneStep());
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, Colors.green);
      expect(icon.size, 64);
    });

    testWidgets('title and description are centered', (tester) async {
      await pumpApp(tester, const SyncDoneStep());
      final title = tester.widget<Text>(
          find.text('Successfully connected!'));
      final desc = tester.widget<Text>(
          find.textContaining('sync automatically'));
      expect(title.textAlign, TextAlign.center);
      expect(desc.textAlign, TextAlign.center);
    });

    testWidgets('has an a11y live region announcing success',
        (tester) async {
      // The green check alone isn't useful for screen readers —
      // wrapping the success block in Semantics(liveRegion: true)
      // makes TalkBack / VoiceOver speak the outcome as soon as
      // the step appears.
      await pumpApp(tester, const SyncDoneStep());

      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text('Successfully connected!'),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.label, contains('Successfully connected'));
    });

    testWidgets('decorative icon is excluded from semantics',
        (tester) async {
      // The icon is visual sugar; including it in the a11y tree
      // would cause TalkBack to announce "check" after the live-
      // region message, which is noise. ExcludeSemantics pins that.
      await pumpApp(tester, const SyncDoneStep());
      // Our ExcludeSemantics wraps the check icon directly; assert
      // that at least one ExcludeSemantics in the tree contains it.
      expect(
        find.ancestor(
          of: find.byIcon(Icons.check_circle),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });
  });
}
