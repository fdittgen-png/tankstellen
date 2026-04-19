import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/payment/domain/qr_payment_decoder.dart';
import 'package:tankstellen/features/payment/presentation/scan_payment_dispatcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  setUp(() {
    _launchedUris.clear();
    ScanPaymentDispatcher.launcher = _fakeLauncher;
    ScanPaymentDispatcher.probe = _alwaysTrueProbe;
  });

  tearDown(ScanPaymentDispatcher.resetForTesting);

  group('ScanPaymentDispatcher.handle (#587)', () {
    test('QrPaymentUrl → launcher called with the same URI', () async {
      _launcherReturn = true;
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentUrl('https://example.com/pay?id=42'),
      );
      expect(outcome, ScanPaymentOutcome.launched);
      expect(_launchedUris.single.toString(),
          'https://example.com/pay?id=42');
    });

    test('QrPaymentAppLink → launcher called with the scheme URI',
        () async {
      _launcherReturn = true;
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentAppLink(
          uri: 'payconiq://payment/abc',
          schemeLabel: 'Payconiq',
        ),
      );
      expect(outcome, ScanPaymentOutcome.launched);
      expect(_launchedUris.single.toString(), 'payconiq://payment/abc');
    });

    test('QrPaymentEpc → confirmEpc, no launch side effect', () async {
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentEpc(
          raw: 'BCD...',
          beneficiary: 'ACME',
          iban: 'DE89370400440532013000',
          amountEur: 42.5,
        ),
      );
      expect(outcome, ScanPaymentOutcome.confirmEpc);
      expect(_launchedUris, isEmpty);
    });

    test('QrPaymentUnknown → unknown outcome', () async {
      final outcome =
          await ScanPaymentDispatcher.handle(const QrPaymentUnknown('???'));
      expect(outcome, ScanPaymentOutcome.unknown);
      expect(_launchedUris, isEmpty);
    });

    test('launcher returning false → launchFailed', () async {
      _launcherReturn = false;
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentUrl('https://example.com'),
      );
      expect(outcome, ScanPaymentOutcome.launchFailed);
    });

    test('launcher throwing → launchFailed (no crash)', () async {
      ScanPaymentDispatcher.launcher =
          (uri, {mode = LaunchMode.externalApplication}) async {
        throw Exception('boom');
      };
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentUrl('https://example.com'),
      );
      expect(outcome, ScanPaymentOutcome.launchFailed);
    });
  });

  group('buildEpcDialog (#587)', () {
    testWidgets('renders beneficiary, IBAN, amount rows', (tester) async {
      await _pumpEpcDialog(
        tester,
        const QrPaymentEpc(
          raw: '',
          beneficiary: 'ACME GmbH',
          iban: 'DE89370400440532013000',
          amountEur: 42.5,
        ),
      );

      expect(find.text('ACME GmbH'), findsOneWidget);
      expect(find.text('DE89370400440532013000'), findsOneWidget);
      expect(find.text('42.50 €'), findsOneWidget);
    });

    testWidgets('Cancel pops with false', (tester) async {
      await _pumpEpcDialog(
        tester,
        const QrPaymentEpc(raw: ''),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_dialogResult, isFalse);
    });
  });
}

// --- test fakes ---------------------------------------------------

final List<Uri> _launchedUris = [];
bool _launcherReturn = true;

Future<bool> _fakeLauncher(Uri uri, {LaunchMode mode = LaunchMode.externalApplication}) async {
  _launchedUris.add(uri);
  return _launcherReturn;
}

Future<bool> _alwaysTrueProbe(Uri uri) async => true;

bool? _dialogResult;

Future<void> _pumpEpcDialog(
    WidgetTester tester, QrPaymentEpc epc) async {
  _dialogResult = null;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (outer) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                _dialogResult = await showDialog<bool>(
                  context: outer,
                  builder: (ctx) =>
                      ScanPaymentDispatcher.buildEpcDialog(ctx, epc),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
