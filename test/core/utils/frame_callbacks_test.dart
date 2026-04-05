import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/frame_callbacks.dart';

void main() {
  group('safePostFrame', () {
    testWidgets('runs the callback after a frame', (tester) async {
      var invocations = 0;
      await tester.pumpWidget(MaterialApp(
        home: _Harness(onInit: (state) => state.safePostFrame(() => invocations++)),
      ));
      // pumpWidget pumps a frame, which drains post-frame callbacks.
      expect(invocations, 1);
    });

    testWidgets('skips callback after widget is unmounted', (tester) async {
      var invocations = 0;
      _HarnessState? captured;
      await tester.pumpWidget(MaterialApp(
        home: _Harness(onInit: (state) => captured = state),
      ));
      expect(captured, isNotNull);

      // Schedule a callback from a live state, then replace the tree so that
      // the state is disposed before the next frame drains callbacks.
      captured!.safePostFrame(() => invocations++);
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      // Force another frame to ensure any scheduled callback has had its shot.
      SchedulerBinding.instance.scheduleFrame();
      await tester.pump();

      expect(invocations, 0);
    });
  });
}

typedef _OnInit = void Function(_HarnessState state);

class _Harness extends StatefulWidget {
  const _Harness({required this.onInit});
  final _OnInit onInit;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  void initState() {
    super.initState();
    widget.onInit(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
