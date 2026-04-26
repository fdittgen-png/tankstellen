import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error_reporting/error_report_payload.dart';
import 'package:tankstellen/core/error_reporting/error_reporter.dart';
import 'package:tankstellen/features/report/domain/entities/report_type.dart';
import 'package:tankstellen/features/report/presentation/screens/report_submit_handler.dart';
import 'package:tankstellen/features/report/providers/report_form_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

/// Direct unit/widget coverage for [ReportSubmitHandler] — sibling to the
/// end-to-end coverage in `report_screen_test.dart`. The handler is mostly
/// glue between the screen state, three statically-coupled backends
/// (Tankerkoenig / TankSync / GitHub), and the localized snackbars, so
/// the goal here is to lock down the *cleanly reachable* paths:
///
/// - the early-return validation guards (no async work, no backends),
/// - the `_routeToGitHub` branch (fully isolated via the injectable
///   [ErrorReporter] parameter),
/// - the no-backend error banner (visible via the SnackBar widget).
///
/// Out of scope (intentional, see PR body): the Tankerkoenig and TankSync
/// submission branches, plus the `ApiException` catch — those depend on
/// un-mockable static singletons (`TankSyncClient`, `ReportService`,
/// `CommunityReportService`) and can't be exercised without refactoring
/// the production class.
void main() {
  /// Mounts a [ReportSubmitHandler] inside a real widget tree (so the
  /// SnackBar surfaces and `Navigator.maybePop` has a Navigator to talk
  /// to) and exposes the constructed handler via [onReady]. Keeps the
  /// auto-disposed `reportFormControllerProvider` alive by `ref.watch`
  /// inside the host widget — without that, the provider tears down
  /// between the seed and the `submit()` call and we read back a fresh
  /// `selectedType: null` state.
  Future<({GlobalKey<NavigatorState> navKey})> mountHandler(
    WidgetTester tester, {
    required List<Object> overrides,
    required ReportType? selectedType,
    required TextEditingController priceController,
    required TextEditingController textController,
    required ErrorReporter? reporter,
    required String stationId,
    required void Function(ReportSubmitHandler handler) onReady,
  }) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          // Push an inner route on top of the home so `Navigator.maybePop`
          // has somewhere to pop back to.
          home: Scaffold(
            body: Builder(
              builder: (rootContext) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(rootContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: _HandlerHost(
                          desiredType: selectedType,
                          priceController: priceController,
                          textController: textController,
                          reporter: reporter,
                          stationId: stationId,
                          onReady: onReady,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (navKey: navKey);
  }

  group('ReportSubmitHandler — validation guards (no async path)', () {
    testWidgets('selectedType == null → submit returns silently', (
      tester,
    ) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      final priceCtrl = TextEditingController();
      final textCtrl = TextEditingController();
      late ReportSubmitHandler handler;

      await mountHandler(
        tester,
        overrides: test.overrides,
        selectedType: null,
        priceController: priceCtrl,
        textController: textCtrl,
        reporter: null,
        stationId: 'station-1',
        onReady: (h) => handler = h,
      );

      await handler.submit();
      await tester.pumpAndSettle();

      // No SnackBar should be raised when there is no selection. The
      // production code returns BEFORE entering the try/finally that
      // toggles `setSubmitting(true)`, so absence of any snackbar is
      // sufficient evidence the early-return path was taken.
      expect(find.byType(SnackBar), findsNothing);

      priceCtrl.dispose();
      textCtrl.dispose();
    });

    testWidgets('needsPrice + empty price → shows enter-valid-price error', (
      tester,
    ) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      final priceCtrl = TextEditingController(); // empty!
      final textCtrl = TextEditingController();
      late ReportSubmitHandler handler;

      await mountHandler(
        tester,
        overrides: test.overrides,
        selectedType: ReportType.wrongE5,
        priceController: priceCtrl,
        textController: textCtrl,
        reporter: null,
        stationId: 'station-1',
        onReady: (h) => handler = h,
      );

      await handler.submit();
      await tester.pump();

      expect(
        find.text('Please enter a valid price'),
        findsOneWidget,
        reason: 'wrongE5 with empty price field must surface the '
            'enterValidPrice snackbar and short-circuit',
      );

      priceCtrl.dispose();
      textCtrl.dispose();
    });

    testWidgets('needsText + empty/whitespace text → shows enter-correction',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      final priceCtrl = TextEditingController();
      final textCtrl = TextEditingController(text: '   '); // whitespace only
      late ReportSubmitHandler handler;

      await mountHandler(
        tester,
        overrides: test.overrides,
        selectedType: ReportType.wrongName,
        priceController: priceCtrl,
        textController: textCtrl,
        reporter: null,
        stationId: 'station-1',
        onReady: (h) => handler = h,
      );

      await handler.submit();
      await tester.pump();

      expect(
        find.text('Please enter the correction'),
        findsOneWidget,
        reason: 'wrongName with whitespace-only text must surface the '
            'enterCorrection snackbar (text.trim().isEmpty)',
      );

      priceCtrl.dispose();
      textCtrl.dispose();
    });
  });

  group('ReportSubmitHandler — _routeToGitHub branch (#508)', () {
    testWidgets(
      'wrongAddress + launched=true → reporter invoked exactly once with '
      'correct payload + success snackbar shown',
      (tester) async {
        final captured = <ErrorReportPayload>[];
        final reporter = _RecordingErrorReporter(
          launched: true,
          onReport: captured.add,
        );

        final test = standardTestOverrides(country: Countries.france);
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);
        when(() => test.mockStorage.getApiKey()).thenReturn(null);

        final priceCtrl = TextEditingController();
        final textCtrl = TextEditingController(
          text: '42 rue de la République, 34310 Montagnac',
        );
        late ReportSubmitHandler handler;

        await mountHandler(
          tester,
          overrides: test.overrides,
          selectedType: ReportType.wrongAddress,
          priceController: priceCtrl,
          textController: textCtrl,
          reporter: reporter,
          stationId: 'station-42',
          onReady: (h) => handler = h,
        );

        await handler.submit();
        await tester.pumpAndSettle();

        expect(captured, hasLength(1),
            reason: 'reporter must be invoked exactly once');
        final payload = captured.single;
        expect(payload.errorType, 'WrongMetadataReport');
        expect(payload.countryCode, 'FR');
        expect(payload.errorMessage, contains('station-42'));
        expect(
          payload.errorMessage,
          contains('42 rue de la République, 34310 Montagnac'),
          reason: 'payload must carry the trimmed correction text',
        );
        expect(
          payload.errorMessage,
          contains(ReportType.wrongAddress.fuelTypeColumnValue),
          reason: 'payload prefixes the report kind (e.g. "address")',
        );
        // sourceLabel falls back to country.apiProvider when present.
        expect(
          payload.sourceLabel,
          equals(Countries.france.apiProvider ?? Countries.france.name),
        );

        // Success snackbar must surface for launched=true.
        expect(find.text('Report sent. Thank you!'), findsOneWidget);

        priceCtrl.dispose();
        textCtrl.dispose();
      },
    );

    testWidgets(
      'wrongName on DE still routes to GitHub (Tankerkoenig is bypassed '
      'for metadata even with an API key)',
      (tester) async {
        final captured = <ErrorReportPayload>[];
        final reporter = _RecordingErrorReporter(
          launched: true,
          onReport: captured.add,
        );

        // DE + a Tankerkoenig key — the routesToGitHub short-circuit
        // must still fire BEFORE either backend is consulted.
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey()).thenReturn(true);
        when(() => test.mockStorage.getApiKey())
            .thenReturn('11111111-2222-3333-4444-555555555555');

        final priceCtrl = TextEditingController();
        final textCtrl = TextEditingController(text: 'Shell Castelnau');
        late ReportSubmitHandler handler;

        await mountHandler(
          tester,
          overrides: test.overrides,
          selectedType: ReportType.wrongName,
          priceController: priceCtrl,
          textController: textCtrl,
          reporter: reporter,
          stationId: 'station-99',
          onReady: (h) => handler = h,
        );

        await handler.submit();
        await tester.pumpAndSettle();

        expect(captured, hasLength(1));
        final payload = captured.single;
        expect(payload.countryCode, 'DE');
        expect(payload.errorType, 'WrongMetadataReport');
        expect(payload.errorMessage, contains('station-99'));
        expect(payload.errorMessage, contains('Shell Castelnau'));

        priceCtrl.dispose();
        textCtrl.dispose();
      },
    );

    testWidgets(
      'launched=false → reporter still invoked, but NO success snackbar '
      'and the route stays on screen (no maybePop)',
      (tester) async {
        final captured = <ErrorReportPayload>[];
        final reporter = _RecordingErrorReporter(
          launched: false,
          onReport: captured.add,
        );

        final test = standardTestOverrides(country: Countries.france);
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);
        when(() => test.mockStorage.getApiKey()).thenReturn(null);

        final priceCtrl = TextEditingController();
        final textCtrl = TextEditingController(text: 'Some other address');
        late ReportSubmitHandler handler;

        final mounted = await mountHandler(
          tester,
          overrides: test.overrides,
          selectedType: ReportType.wrongAddress,
          priceController: priceCtrl,
          textController: textCtrl,
          reporter: reporter,
          stationId: 'station-7',
          onReady: (h) => handler = h,
        );

        // Snapshot how many routes are stacked before submit; must stay
        // identical when launched=false.
        final navState = mounted.navKey.currentState!;
        final beforeRoutes = _countRoutes(navState);

        await handler.submit();
        await tester.pumpAndSettle();

        expect(captured, hasLength(1),
            reason: 'reporter must still be invoked even when the launch '
                'fails — the production code only gates the snackbar + '
                'pop on the `launched` boolean.');
        expect(
          find.text('Report sent. Thank you!'),
          findsNothing,
          reason: 'launched=false must NOT show the success snackbar',
        );

        // Route stack length must be unchanged: with maybePop suppressed
        // we should still be on the inner route.
        expect(_countRoutes(navState), equals(beforeRoutes),
            reason: 'No route was popped because launched=false');

        priceCtrl.dispose();
        textCtrl.dispose();
      },
    );
  });

  group('ReportSubmitHandler — no-backend error branch', () {
    testWidgets(
      'FR + selectedType=wrongE5 (price report, not GitHub-routed) + '
      'TankSync disconnected → reportNoBackendAvailable snackbar shown',
      (tester) async {
        // FR has no Tankerkoenig endpoint, and the standardTestOverrides
        // syncStateProvider returns a disabled SyncConfig (no userId,
        // not connected). With selectedType=wrongE5 the handler walks
        // past the validation guards (price field is non-empty), past
        // the routesToGitHub check (false for wrongE5), and lands on
        // the no-backend banner branch.
        final test = standardTestOverrides(country: Countries.france);
        when(() => test.mockStorage.hasApiKey()).thenReturn(false);
        when(() => test.mockStorage.getApiKey()).thenReturn(null);

        final priceCtrl = TextEditingController(text: '1.459');
        final textCtrl = TextEditingController();
        late ReportSubmitHandler handler;

        await mountHandler(
          tester,
          overrides: test.overrides,
          selectedType: ReportType.wrongE5,
          priceController: priceCtrl,
          textController: textCtrl,
          reporter: null,
          stationId: 'station-fr',
          onReady: (h) => handler = h,
        );

        await handler.submit();
        await tester.pumpAndSettle();

        // Match by ARB substring so future copy edits to the long
        // sentence don't break the assertion. The English ARB starts
        // with "The report could not be sent".
        expect(
          find.textContaining('could not be sent'),
          findsOneWidget,
          reason: 'wrongE5 in FR with no TankSync must show the '
              'reportNoBackendAvailable snackbar',
        );

        priceCtrl.dispose();
        textCtrl.dispose();
      },
    );
  });
}

/// Counts the number of routes currently on the navigator stack.
/// `popUntil` walks from top to bottom and returning `true` for the
/// predicate stops the walk without actually popping anything.
int _countRoutes(NavigatorState state) {
  var count = 0;
  state.popUntil((_) {
    count++;
    return true;
  });
  return count;
}

/// Hosts the [ReportSubmitHandler] inside a `ConsumerStatefulWidget` so
/// we can:
/// 1. seed `reportFormControllerProvider` with the desired type
///    exactly once, in `initState` (post-frame so the notifier is
///    safely buildable),
/// 2. keep the auto-dispose provider alive across the seed -> submit
///    boundary by `ref.watch`-ing it,
/// 3. publish the constructed handler back to the test via [onReady],
///    only after the seed has settled.
class _HandlerHost extends ConsumerStatefulWidget {
  const _HandlerHost({
    required this.desiredType,
    required this.priceController,
    required this.textController,
    required this.reporter,
    required this.stationId,
    required this.onReady,
  });

  final ReportType? desiredType;
  final TextEditingController priceController;
  final TextEditingController textController;
  final ErrorReporter? reporter;
  final String stationId;
  final void Function(ReportSubmitHandler handler) onReady;

  @override
  ConsumerState<_HandlerHost> createState() => _HandlerHostState();
}

class _HandlerHostState extends ConsumerState<_HandlerHost> {
  bool _seeded = false;
  bool _published = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(reportFormControllerProvider.notifier)
          .selectType(widget.desiredType);
      _seeded = true;
      // Trigger a rebuild so `build` can publish the handler now that
      // the form state matches `desiredType`.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // `watch` is critical: the auto-dispose
    // `reportFormControllerProvider` would otherwise tear down between
    // the seed and the test's later `handler.submit()` call, dropping
    // the selectedType back to null.
    final form = ref.watch(reportFormControllerProvider);
    if (_seeded && !_published && form.selectedType == widget.desiredType) {
      _published = true;
      // Defer the callback by one frame so the test sees a fully
      // settled tree (no in-flight setState) when it dispatches submit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onReady(
          ReportSubmitHandler(
            context: context,
            ref: ref,
            stationId: widget.stationId,
            priceController: widget.priceController,
            textController: widget.textController,
            reporter: widget.reporter,
          ),
        );
      });
    }
    return const SizedBox.shrink();
  }
}

/// Test double for [ErrorReporter] that captures the payload and skips
/// both the consent dialog and the URL launcher. Mirrors the
/// `_RecordingReporter` pattern in `report_screen_test.dart` but
/// configurable so we can drive the launched=true / launched=false
/// branches independently.
class _RecordingErrorReporter extends ErrorReporter {
  _RecordingErrorReporter({
    required this.launched,
    required this.onReport,
  }) : super(launcher: _noopLauncher);

  final bool launched;
  final void Function(ErrorReportPayload payload) onReport;

  static Future<bool> _noopLauncher(Uri _) async => true;

  @override
  Future<bool> reportError(
    BuildContext context,
    ErrorReportPayload payload, {
    bool requireConsent = true,
  }) async {
    onReport(payload);
    return launched;
  }
}
