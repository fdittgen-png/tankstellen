// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_handler/share_handler.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/'
    'share_receipt_listener.dart';
import 'package:tankstellen/features/consumption/providers/'
    'pending_shared_receipt_provider.dart';
import 'package:tankstellen/features/feature_management/application/'
    'feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Fake [ShareHandlerPlatform] whose cold-launch media + warm stream the
/// test drives. `initialThrows` forces `getInitialSharedMedia` to throw,
/// and `addError` on [controller] simulates a platform-channel stream
/// fault — both #2349 fault-injection seams.
class _FakeShareHandler extends ShareHandlerPlatform
    with MockPlatformInterfaceMixin {
  _FakeShareHandler({this.initial, this.initialThrows = false});

  final SharedMedia? initial;
  final bool initialThrows;
  // Closed by the test's addTearDown — the linter can't trace it there.
  // ignore: close_sinks
  final controller = StreamController<SharedMedia>.broadcast();

  @override
  Future<SharedMedia?> getInitialSharedMedia() async {
    if (initialThrows) throw StateError('initial-media probe barfed');
    return initial;
  }

  @override
  Stream<SharedMedia> get sharedMediaStream => controller.stream;
}

/// A real [GoRouter] with `/` + `/consumption/add` so a routed share can
/// be asserted via the landed route (GoRouter is a factory — it cannot
/// be subclassed, so we drive a real one, same as the notification test).
GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/consumption/add',
          builder: (_, _) => const Text('add-fill-up'),
        ),
      ],
    );

SharedMedia _imageMedia(String path) => SharedMedia(
      attachments: [
        SharedAttachment(path: path, type: SharedAttachmentType.image),
      ],
    );

Future<ProviderContainer> _pumpListener(
  WidgetTester tester, {
  required _FakeShareHandler handler,
  required GoRouter router,
  Set<Feature> enabled = const {Feature.addFillUpShareIntentReceipt},
  bool gateThrows = false,
}) async {
  addTearDown(() => handler.controller.close());
  final container = ProviderContainer(
    overrides: [
      if (gateThrows)
        enabledFeaturesProvider
            .overrideWith((_) => throw StateError('flags box closed'))
      else
        enabledFeaturesProvider.overrideWithValue(enabled),
      routerProvider.overrideWith((ref) => router),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => ShareReceiptListener(
          shareHandler: handler,
          child: child ?? const SizedBox(),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  silenceErrorLoggerSpool();

  group('ShareReceiptListener — warm share', () {
    testWidgets('a streamed image share is routed through the handler',
        (tester) async {
      final handler = _FakeShareHandler();
      final container = await _pumpListener(
        tester,
        handler: handler,
        router: _router(),
      );

      handler.controller.add(_imageMedia('/tmp/warm.jpg'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), '/tmp/warm.jpg');
      expect(find.text('add-fill-up'), findsOneWidget);
    });
  });

  group('ShareReceiptListener — cold share', () {
    testWidgets('the initial shared media is dispatched after first frame',
        (tester) async {
      final handler = _FakeShareHandler(initial: _imageMedia('/tmp/cold.jpg'));
      final container = await _pumpListener(
        tester,
        handler: handler,
        router: _router(),
      );

      // getInitialSharedMedia resolves async, then a post-frame callback
      // dispatches it — settle to drain both.
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptProvider), '/tmp/cold.jpg');
      expect(find.text('add-fill-up'), findsOneWidget);
    });
  });

  group('ShareReceiptListener — never throws (#2349 fault injection)', () {
    testWidgets(
        'a failing initial probe + a stream error + a throwing downstream '
        'still pump normally', (tester) async {
      // Cold probe throws, the gate read throws (handler downstream
      // fault), and the warm stream emits a raw error event — all three
      // surfaces the listener funnels. None may escape as an unhandled
      // async error or fail the pump.
      final handler = _FakeShareHandler(initialThrows: true);
      await _pumpListener(
        tester,
        handler: handler,
        router: _router(),
        gateThrows: true,
      );
      await tester.pumpAndSettle();

      // A warm image share whose downstream gate read throws — emitting it
      // must return normally (the dispatch is synchronous; the throw is
      // caught inside the handler, never propagated out of the callback).
      expect(
        () => handler.controller.add(_imageMedia('/tmp/boom.jpg')),
        returnsNormally,
        reason: 'a thrown downstream must be swallowed, not propagated '
            'out of the stream callback (#2349)',
      );
      await tester.pump();

      // A raw stream error event — caught by the listener's onError.
      expect(
        () => handler.controller.addError(StateError('platform channel error')),
        returnsNormally,
      );
      await tester.pump();

      // No exception bubbled out of the pumps — the listener is alive,
      // still showing home (nothing was routed because the gate threw).
      expect(find.text('home'), findsOneWidget);
    });
  });
}
