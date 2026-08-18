// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/payment/domain/qr_payment_decoder.dart';
import 'package:tankstellen/features/payment/presentation/scan_payment_dispatcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  setUp(() {
    _launchedUris.clear();
    _launcherReturn = true;
    ScanPaymentDispatcher.launcher = _fakeLauncher;
    ScanPaymentDispatcher.probe = _alwaysTrueProbe;
  });

  tearDown(ScanPaymentDispatcher.resetForTesting);

  group('ScanPaymentDispatcher.handle (#587)', () {
    test('#3611 — QrPaymentUrl → confirmUrl, NO auto-launch', () async {
      _launcherReturn = true;
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentUrl('https://example.com/pay?id=42'),
      );
      expect(outcome, ScanPaymentOutcome.confirmUrl);
      expect(_launchedUris, isEmpty,
          reason: 'a scanned URL must never launch before the user has '
              'confirmed the host');
    });

    test('#3611 — launchConfirmedUrl launches the confirmed URI', () async {
      _launcherReturn = true;
      final outcome = await ScanPaymentDispatcher.launchConfirmedUrl(
        const QrPaymentUrl('https://example.com/pay?id=42'),
      );
      expect(outcome, ScanPaymentOutcome.launched);
      expect(_launchedUris.single.toString(), 'https://example.com/pay?id=42');
    });

    test('#3611 — launchConfirmedUrl surfaces launchFailed', () async {
      _launcherReturn = false;
      final outcome = await ScanPaymentDispatcher.launchConfirmedUrl(
        const QrPaymentUrl('https://example.com/pay'),
      );
      expect(outcome, ScanPaymentOutcome.launchFailed);
    });

    test('#3611 — displayHostOf shows the bare host for https, '
        'scheme-prefixed otherwise', () {
      expect(
        ScanPaymentDispatcher.displayHostOf(
            Uri.parse('https://pay.example.com/x?y=1')),
        'pay.example.com',
      );
      expect(
        ScanPaymentDispatcher.displayHostOf(
            Uri.parse('http://pay.example.com/x')),
        'http://pay.example.com',
      );
    });

    test('QrPaymentAppLink → launcher called with the scheme URI', () async {
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
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentUnknown('???'),
      );
      expect(outcome, ScanPaymentOutcome.unknown);
      expect(_launchedUris, isEmpty);
    });

    test('launcher returning false → launchFailed', () async {
      _launcherReturn = false;
      // #3611 — URL launches go through launchConfirmedUrl now; an
      // app-link exercises the same _tryLaunch path via handle().
      final outcome = await ScanPaymentDispatcher.handle(
        const QrPaymentAppLink(uri: 'twint://pay', schemeLabel: 'TWINT'),
      );
      expect(outcome, ScanPaymentOutcome.launchFailed);
    });

    test('launcher throwing → launchFailed (no crash)', () async {
      ScanPaymentDispatcher.launcher =
          (uri, {mode = LaunchMode.externalApplication}) async {
            throw Exception('boom');
          };
      final outcome = await ScanPaymentDispatcher.launchConfirmedUrl(
        const QrPaymentUrl('https://example.com'),
      );
      expect(outcome, ScanPaymentOutcome.launchFailed);
    });
  });

  group('tryLaunchEpc (#720)', () {
    const sample = QrPaymentEpc(
      raw: 'BCD',
      beneficiary: 'ACME GmbH',
      iban: 'DE89370400440532013000',
      amountEur: 42.5,
    );

    test('prefers sepa:// scheme when a handler is installed', () async {
      ScanPaymentDispatcher.probe = (uri) async => uri.scheme == 'sepa';
      final outcome = await ScanPaymentDispatcher.tryLaunchEpc(sample);
      expect(outcome, EpcLaunchOutcome.launched);
      expect(_launchedUris.single.scheme, 'sepa');
      expect(
        _launchedUris.single.queryParameters['iban'],
        'DE89370400440532013000',
      );
      expect(_launchedUris.single.queryParameters['amount'], '42.50');
    });

    test('falls back to iban:// when sepa is unhandled', () async {
      ScanPaymentDispatcher.probe = (uri) async => uri.scheme == 'iban';
      final outcome = await ScanPaymentDispatcher.tryLaunchEpc(sample);
      expect(outcome, EpcLaunchOutcome.launched);
      expect(_launchedUris.single.scheme, 'iban');
    });

    test('falls back to clipboard when no scheme handler exists', () async {
      ScanPaymentDispatcher.probe = (_) async => false;
      _clipboardWrites.clear();
      ScanPaymentDispatcher.clipboardWriter = (text) async =>
          _clipboardWrites.add(text);

      final outcome = await ScanPaymentDispatcher.tryLaunchEpc(sample);
      expect(outcome, EpcLaunchOutcome.copiedToClipboard);
      expect(_launchedUris, isEmpty);
      expect(_clipboardWrites.single, contains('DE89370400440532013000'));
      expect(_clipboardWrites.single, contains('42.50'));
    });

    test('clipboard failure surfaces as failed outcome', () async {
      ScanPaymentDispatcher.probe = (_) async => false;
      ScanPaymentDispatcher.clipboardWriter = (_) async =>
          throw Exception('no clipboard');
      final outcome = await ScanPaymentDispatcher.tryLaunchEpc(sample);
      expect(outcome, EpcLaunchOutcome.failed);
    });

    test(
      'missing IBAN → failed (cannot copy or launch anything useful)',
      () async {
        ScanPaymentDispatcher.probe = (_) async => false;
        const noIban = QrPaymentEpc(raw: 'BCD', beneficiary: 'ACME');
        final outcome = await ScanPaymentDispatcher.tryLaunchEpc(noIban);
        expect(outcome, EpcLaunchOutcome.failed);
      },
    );
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
      expect(find.text('42,50 €'), findsOneWidget);
    });

    testWidgets('Cancel pops with false', (tester) async {
      await _pumpEpcDialog(tester, const QrPaymentEpc(raw: ''));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_dialogResult, isFalse);
    });
  });

  group('confirmAndLaunchUrl (#3611)', () {
    testWidgets('a URL QR shows the confirmation dialog with the host',
        (tester) async {
      await _pumpUrlConfirm(
          tester, const QrPaymentUrl('https://pay.example.com/x?id=1'));

      expect(find.byKey(const Key('qr_launch_confirm_open')), findsOneWidget);
      expect(find.byKey(const Key('qr_launch_confirm_cancel')),
          findsOneWidget);
      expect(find.textContaining('pay.example.com'), findsOneWidget);
      expect(_launchedUris, isEmpty,
          reason: 'nothing may launch while the dialog is up');
    });

    testWidgets('a plain-http URL shows the scheme alongside the host',
        (tester) async {
      await _pumpUrlConfirm(
          tester, const QrPaymentUrl('http://pay.example.com/x'));

      expect(
          find.textContaining('http://pay.example.com'), findsOneWidget,
          reason: 'a non-https scheme must be visibly flagged (#3611)');
    });

    testWidgets('cancel does NOT launch', (tester) async {
      await _pumpUrlConfirm(
          tester, const QrPaymentUrl('https://pay.example.com/x'));

      await tester.tap(find.byKey(const Key('qr_launch_confirm_cancel')));
      await tester.pumpAndSettle();

      expect(_launchedUris, isEmpty);
      expect(_urlConfirmOutcome, isNull,
          reason: 'cancel yields null — the caller shows no snackbar');
    });

    testWidgets('confirm launches through the launcher seam',
        (tester) async {
      _launcherReturn = true;
      await _pumpUrlConfirm(
          tester, const QrPaymentUrl('https://pay.example.com/x?id=1'));

      await tester.tap(find.byKey(const Key('qr_launch_confirm_open')));
      await tester.pumpAndSettle();

      expect(_launchedUris.single.toString(), 'https://pay.example.com/x?id=1');
      expect(_urlConfirmOutcome, ScanPaymentOutcome.launched);
    });
  });
}

// --- test fakes ---------------------------------------------------

final List<Uri> _launchedUris = [];
final List<String> _clipboardWrites = [];
bool _launcherReturn = true;

Future<bool> _fakeLauncher(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  _launchedUris.add(uri);
  return _launcherReturn;
}

Future<bool> _alwaysTrueProbe(Uri uri) async => true;

bool? _dialogResult;
ScanPaymentOutcome? _urlConfirmOutcome;

/// Pumps a host screen whose button runs the full #3611
/// confirm-then-launch flow, then taps it so the dialog is showing.
Future<void> _pumpUrlConfirm(WidgetTester tester, QrPaymentUrl target) async {
  _urlConfirmOutcome = null;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (outer) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                _urlConfirmOutcome =
                    await ScanPaymentDispatcher.confirmAndLaunchUrl(
                        outer, target);
              },
              child: const Text('scan'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('scan'));
  await tester.pumpAndSettle();
}

Future<void> _pumpEpcDialog(WidgetTester tester, QrPaymentEpc epc) async {
  _dialogResult = null;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
