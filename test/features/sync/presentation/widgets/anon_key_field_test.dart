import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/anon_key_field.dart';

import '../../../../helpers/pump_app.dart';

/// Build a valid-looking JWT string of the given total length.
/// Produces `aaa.bbb.ccc...` with the signature padded out so the
/// string satisfies AnonKeyField's "3 dot-separated parts + length"
/// validation.
String _jwt(int length) {
  const head = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
  const payload = 'eyJzdWIiOiIxMjM0NTY3ODkwIn0';
  final remaining = length - head.length - payload.length - 2;
  return '$head.$payload.${'a' * (remaining.clamp(1, 10000))}';
}

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  AnonKeyField build({
    bool showKey = false,
    VoidCallback? onToggleVisibility,
    VoidCallback? onChanged,
  }) =>
      AnonKeyField(
        controller: controller,
        showKey: showKey,
        onToggleVisibility: onToggleVisibility ?? () {},
        onChanged: onChanged,
      );

  group('AnonKeyField — visibility toggle', () {
    testWidgets('shows visibility_off icon when showKey is true',
        (tester) async {
      await pumpApp(tester, build(showKey: true));
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('shows visibility icon when showKey is false',
        (tester) async {
      await pumpApp(tester, build(showKey: false));
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('tap on the eye icon invokes onToggleVisibility',
        (tester) async {
      var toggled = 0;
      await pumpApp(
        tester,
        build(showKey: false, onToggleVisibility: () => toggled++),
      );
      await tester.tap(find.byIcon(Icons.visibility));
      expect(toggled, 1);
    });
  });

  group('AnonKeyField — length badge', () {
    testWidgets('hidden when the field is empty', (tester) async {
      await pumpApp(tester, build());
      // Length badge text is only shown for keyLen > 0.
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows character count when text is entered',
        (tester) async {
      controller.text = 'abc';
      await pumpApp(tester, build());
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('AnonKeyField — helper text', () {
    testWidgets('no helper text when empty', (tester) async {
      await pumpApp(tester, build());
      // The label "Anon Key" is visible, but there's no helper-style
      // message like "Key looks correct" / "Key may be truncated".
      expect(find.textContaining('looks correct'), findsNothing);
      expect(find.textContaining('may be truncated'), findsNothing);
      expect(find.textContaining('too long'), findsNothing);
      expect(find.textContaining('should be a JWT'), findsNothing);
    });

    testWidgets('truncated warning for a short non-JWT-shaped string',
        (tester) async {
      controller.text = 'short-value';
      await pumpApp(tester, build());
      // "Key may be truncated" or "Key should be a JWT" depending on
      // length; both are orange/red hints.
      expect(find.textContaining('JWT'), findsOneWidget);
    });

    testWidgets('non-JWT format above 10 chars triggers the JWT hint',
        (tester) async {
      controller.text = 'not-a-jwt-but-long-enough';
      await pumpApp(tester, build());
      expect(find.textContaining('JWT'), findsOneWidget);
    });

    testWidgets('valid-length JWT surfaces the "looks correct" message',
        (tester) async {
      controller.text = _jwt(AnonKeyField.minExpectedKeyLength + 5);
      await pumpApp(tester, build());
      expect(find.textContaining('looks correct'), findsOneWidget);
    });

    testWidgets('over-max length surfaces the errorText', (tester) async {
      // Flutter's InputDecoration hides helperText when errorText is
      // set, so the visible cue is the error message. Pin it.
      controller.text = _jwt(AnonKeyField.maxKeyLength + 50);
      await pumpApp(tester, build());
      expect(find.text('Key exceeds maximum length'), findsOneWidget);
    });
  });

  group('AnonKeyField — change callback', () {
    testWidgets('onChanged fires whenever the user edits the field',
        (tester) async {
      var changes = 0;
      await pumpApp(tester, build(onChanged: () => changes++));
      await tester.enterText(find.byType(TextField), 'x');
      expect(changes, greaterThanOrEqualTo(1));
    });
  });

  group('AnonKeyField — obscureText', () {
    testWidgets('obscures the text when showKey is false', (tester) async {
      controller.text = _jwt(210);
      await pumpApp(tester, build(showKey: false));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
    });

    testWidgets('reveals the text (multi-line) when showKey is true',
        (tester) async {
      controller.text = _jwt(210);
      await pumpApp(tester, build(showKey: true));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
      expect(field.maxLines, 3);
    });
  });
}
