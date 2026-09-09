// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'build_method_scan.dart';

/// Widget constructor arity (#3985, epic #3952).
///
/// ## The definition — widgets ONLY
///
/// A violation is a class that `extends StatelessWidget`,
/// `StatefulWidget`, `ConsumerWidget` or `ConsumerStatefulWidget` whose
/// named constructor declares **15 or more** parameters.
///
/// The restriction to widgets is the whole point. The audit that
/// prompted this task counted every long constructor and led with
/// `TripLiveReading` (37 fields), `TripSample` (30) and `CountryConfig`
/// (23) — value classes, where a field per measured quantity is exactly
/// right and shortening the list would mean losing data. Arity is a
/// smell in a WIDGET, where it means the caller is hand-threading state
/// that a record, a provider or a smaller widget should carry.
///
/// ## The baseline
///
/// **6**, measured with the scan below:
/// `VehicleEditForm` (24), `StationMapLayers` (23),
/// `AddFillUpFormFields` (22), `StationMapBody` (18),
/// `VehicleDrivetrainSection` (16), `PageScaffold` (16).
///
/// Decrease-only. NEVER raise it.
const _baseline = 6;

/// Where the smell starts. Chosen so the six above are in and the next
/// widget down (14) is out — the ratchet caps today's worst rather than
/// inventing a target nobody measured.
const _threshold = 15;

void main() {
  test('no new widget takes $_threshold+ constructor parameters (#3985)', () {
    final offenders = <String>[];
    for (final file in libFiles()) {
      final src = file.readAsStringSync();
      for (final widget in widgetArities(src)) {
        if (widget.params >= _threshold) {
          offenders.add(
            '${posixPath(file)}  ${widget.name} (${widget.params})',
          );
        }
      }
    }
    offenders.sort();

    expect(
      offenders.length,
      lessThanOrEqualTo(_baseline),
      reason: 'Widgets with $_threshold+ constructor parameters: '
          '${offenders.length} (baseline $_baseline, decrease-only). Group '
          'the arguments into a record or a small state object, or split '
          'the widget — see #3985.\n${offenders.join("\n")}',
    );
  });

  test('the scan counts widget constructors and not value classes '
      '— fidelity check', () {
    const src = '''
class BigWidget extends StatelessWidget {
  const BigWidget({
    super.key,
    required this.a,
    required this.b,
    this.c,
  });
  final int a;
  final int b;
  final int? c;
}

class BigModel {
  const BigModel({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
  });
  final int a;
  final int b;
  final int c;
  final int d;
}
''';
    final found = widgetArities(src).toList();
    // The widget is seen with its three real parameters (`super.key`
    // does not count — it is not state the caller threads through).
    expect(found, [(name: 'BigWidget', params: 3)]);
    // The value class is not a widget and must not appear at all.
    expect(found.map((e) => e.name), isNot(contains('BigModel')));
  });
}
