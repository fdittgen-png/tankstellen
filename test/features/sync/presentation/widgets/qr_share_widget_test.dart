import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/sync/presentation/widgets/qr_share_widget.dart';

import '../../../../helpers/pump_app.dart';

class _FixedSyncState extends SyncState {
  final SyncConfig _value;
  _FixedSyncState(this._value);

  @override
  SyncConfig build() => _value;
}

/// Mocks the system Clipboard.setData channel so copy-button tests
/// run without the real clipboard.
void _mockClipboard(List<String> captured) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      final text = (call.arguments as Map)['text'] as String?;
      if (text != null) captured.add(text);
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrShareWidget', () {
    testWidgets('renders nothing when sync is not configured',
        (tester) async {
      await pumpApp(
        tester,
        const QrShareWidget(),
        overrides: [
          syncStateProvider.overrideWith(
            () => _FixedSyncState(const SyncConfig()),
          ),
        ],
      );

      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Share your database'), findsNothing);
    });

    testWidgets('renders nothing when URL is set but key is missing',
        (tester) async {
      await pumpApp(
        tester,
        const QrShareWidget(),
        overrides: [
          syncStateProvider.overrideWith(
            () => _FixedSyncState(const SyncConfig(
              enabled: true,
              supabaseUrl: 'https://x.supabase.co',
            )),
          ),
        ],
      );
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('renders QR + title + copy button when fully configured',
        (tester) async {
      await pumpApp(
        tester,
        const QrShareWidget(),
        overrides: [
          syncStateProvider.overrideWith(
            () => _FixedSyncState(const SyncConfig(
              enabled: true,
              supabaseUrl: 'https://x.supabase.co',
              supabaseAnonKey: 'anon-key',
            )),
          ),
        ],
      );

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Share your database'), findsOneWidget);
      expect(find.textContaining('scan this QR code'), findsOneWidget);
      expect(find.text('Copy as text'), findsOneWidget);
    });

    // Note: QrImageView in qr_flutter 4.x does not expose `data` as a
    // getter on the widget, so we validate the encoded payload via
    // the Copy-as-text button instead (it encodes the same JSON).

    testWidgets('Copy as text puts the JSON on the clipboard',
        (tester) async {
      final captured = <String>[];
      _mockClipboard(captured);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await pumpApp(
        tester,
        const QrShareWidget(),
        overrides: [
          syncStateProvider.overrideWith(
            () => _FixedSyncState(const SyncConfig(
              enabled: true,
              supabaseUrl: 'https://x.supabase.co',
              supabaseAnonKey: 'k',
            )),
          ),
        ],
      );

      await tester.tap(find.text('Copy as text'));
      await tester.pump();
      expect(captured, hasLength(1));
      final decoded = jsonDecode(captured.first);
      expect(decoded, {'url': 'https://x.supabase.co', 'key': 'k'});
    });

    testWidgets('QR is wrapped in a white rounded container '
        '(QR-code contrast requirement)', (tester) async {
      // QR readers need a light background to recognise the pattern.
      // Pin the white + rounded wrap so a theme refactor can't break
      // camera scans.
      await pumpApp(
        tester,
        const QrShareWidget(),
        overrides: [
          syncStateProvider.overrideWith(
            () => _FixedSyncState(const SyncConfig(
              enabled: true,
              supabaseUrl: 'u',
              supabaseAnonKey: 'k',
            )),
          ),
        ],
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(QrImageView),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });
  });
}
