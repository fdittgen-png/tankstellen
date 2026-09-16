// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Deterministic consumption replay harness (#4231, Epic #4222).
//
// #4231's first acceptance item: "a deterministic replay command exists
// without UI dependencies". This is that command. It replays a corpus of
// recorded trips through the estimator and reports error against
// fill-up truth, bucketed by SOURCE CLASS — because #4208's merged-in
// content is explicit that thresholds are "per source class, not one
// global number".
//
// ## What this is NOT
//
// It is not the corpus. `test/fixtures/consumption_corpus/` is empty of
// traces, and deliberately so: #4231 requires *real* recordings (native
// fuel-rate, MAF, speed-density, GPS-only and mixed coverage) with
// full-to-full fills for truth, and those need a vehicle, a paired
// adapter and drives. Inventing traces would satisfy the letter of the
// corpus while defeating the validation gate built on it — the gate
// exists to arbitrate the fuzzy path against real pump truth.
//
// So the harness ships first and reports "no traces" until someone drops
// recordings in. That is the useful half: when the recording session
// happens, nothing has to be built.
//
// ## Read-only, and never a gate
//
// Same standing constraint `ratchet_report.dart` carries: this tool
// writes nothing and must not become CI enforcement. New enforcement
// starts advisory or post-merge. A replay threshold becomes a gate only
// once the corpus is real and #4234's retirement gate needs it.
//
// ## Current vs fuzzy (#4232)
//
// Every eligible trace is also replayed through `FuzzyConsumptionEngine`
// (`replay_consumption_fuzzy.dart`) and reported in a second table beside
// the shipped figure, against the same truth — the side-by-side the epic's
// validation gate will read. Still reporting only.
//
// Usage:
//   dart run tool/replay_consumption.dart
//   dart run tool/replay_consumption.dart --corpus path/to/corpus
//
// Tested in-process by test/tool/replay_consumption_test.dart (import +
// call, never spawned — #3752).

import 'dart:convert';
import 'dart:io';

import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';

import 'replay_consumption_fuzzy.dart';

/// Where traces live by default, relative to the repo root.
const String kDefaultCorpusDir = 'test/fixtures/consumption_corpus';

/// The per-tick provenance tags that mean "the ECU reported fuel".
///
/// Same sets as `trip_fuel_source.dart`'s `kMeasuredFuelSourceTags` /
/// `kEstimatedFuelSourceTags`. Restated rather than imported because a
/// `tool/` script must not drag the Flutter-dependent app graph in — the
/// parity is asserted by the in-process test instead.
const Set<String> kMeasuredTags = {'pid9D', 'pidA2', 'pid5E'};
const Set<String> kEstimatedTags = {'maf66', 'maf', 'speedDensity'};

/// A trace's source class, derived from its samples' `'fs'` stamps.
///
/// Mirrors `ConsumptionSourceClass` (#4230) — measured / estimated /
/// gpsOnly / none. The dominant stamp wins, exactly as
/// `dominantFuelSourceOf` decides it for a live trip.
enum ReplaySourceClass { measured, estimated, gpsOnly, none }

/// Validity gates, reused verbatim from `PhysicsScaleCalibrator` rather
/// than re-chosen here.
///
/// A trace the calibrator would refuse as ground truth must not quietly
/// become a corpus entry with looser rules, or the harness would report
/// error on trips production never learns from.
class ReplayGates {
  const ReplayGates._();

  static const double minDistanceKm = 2.0;
  static const double minDurationSeconds = 120.0;
  static const int minSamples = 10;
  static const double maxGapSeconds = 60.0;

  /// The plausibility band `GpsFuelEstimator` clamps to.
  static const double minLPer100Km = 0.5;
  static const double maxLPer100Km = 30.0;
}

/// One corpus trace: a summary sidecar plus its NDJSON samples.
class ReplayTrace {
  ReplayTrace({
    required this.name,
    required this.summary,
    required this.samples,
  });

  final String name;
  final Map<String, dynamic> summary;

  /// Decoded sample maps, in file order (the harness sorts by `'t'`).
  final List<Map<String, dynamic>> samples;

  /// Litres the pump says were burned — the only ground truth #4231
  /// accepts. Null when the trace carries no full-to-full truth, which
  /// makes it usable for coverage but not for error.
  double? get truthLitres => (summary['truthLitres'] as num?)?.toDouble();

  double? get distanceKm => (summary['distanceKm'] as num?)?.toDouble();

  /// The figure the shipped pipeline produced, for the not-worse
  /// comparison the epic's validation gate requires.
  double? get shippedLitres =>
      (summary['fuelLitersConsumed'] as num?)?.toDouble() ??
      (summary['eFuel'] as num?)?.toDouble();

  /// Dominant per-tick provenance → source class.
  ReplaySourceClass get sourceClass {
    final counts = <String, int>{};
    for (final s in samples) {
      final tag = s['fs'];
      if (tag is! String || tag == 'none') continue;
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      // No engine provenance at all. A gpsOnly trip is the honest
      // reading; a summary that claims otherwise carries no stamps and
      // cannot be classified.
      return summary['kind'] == 'gpsOnly'
          ? ReplaySourceClass.gpsOnly
          : ReplaySourceClass.none;
    }
    var best = '';
    var bestCount = -1;
    for (final e in counts.entries) {
      if (e.value > bestCount) {
        best = e.key;
        bestCount = e.value;
      }
    }
    if (kMeasuredTags.contains(best)) return ReplaySourceClass.measured;
    if (kEstimatedTags.contains(best)) return ReplaySourceClass.estimated;
    return ReplaySourceClass.none;
  }

  /// Why this trace cannot serve as an error sample, or null when it can.
  ///
  /// Stated rather than silently skipped: a corpus that drops traces
  /// without saying why looks smaller than it is, and the reason is what
  /// tells the next person which recordings to go and get.
  String? get ineligibleReason {
    if (samples.length < ReplayGates.minSamples) {
      return 'only ${samples.length} samples (need ${ReplayGates.minSamples})';
    }
    final d = distanceKm;
    if (d == null || d < ReplayGates.minDistanceKm) {
      return 'distance ${d ?? '-'} km (need ${ReplayGates.minDistanceKm})';
    }
    final seconds = _durationSeconds();
    if (seconds < ReplayGates.minDurationSeconds) {
      return 'duration ${seconds.toStringAsFixed(0)} s '
          '(need ${ReplayGates.minDurationSeconds.toStringAsFixed(0)})';
    }
    if (truthLitres == null) return 'no full-to-full truth litres';
    return null;
  }

  double _durationSeconds() {
    if (samples.length < 2) return 0;
    final stamps = samples
        .map((s) => (s['t'] as num?)?.toInt())
        .whereType<int>()
        .toList()
      ..sort();
    if (stamps.length < 2) return 0;
    return (stamps.last - stamps.first) / 1000.0;
  }

  /// Whether any sample still carries absolute location.
  ///
  /// #4231 requires location removed or offset **before commit**. The
  /// harness refuses to report on a trace that failed anonymisation
  /// rather than reading it — a corpus leaking coordinates is a privacy
  /// defect, not a data-quality one.
  bool get carriesRawLocation =>
      samples.any((s) => s.containsKey('la') || s.containsKey('lo'));
}

/// Per-source-class error, as #4208 asks for it.
class ReplayBucket {
  ReplayBucket(this.sourceClass);

  final ReplaySourceClass sourceClass;
  final List<double> _litreErrors = [];
  final List<double> _signedRelative = [];
  int traces = 0;
  int ineligible = 0;

  void add({required double truth, required double predicted}) {
    traces++;
    _litreErrors.add((predicted - truth).abs());
    if (truth > 0) _signedRelative.add((predicted - truth) / truth);
  }

  /// Mean absolute integrated-litres error.
  double? get maeLitres => _litreErrors.isEmpty
      ? null
      : _litreErrors.reduce((a, b) => a + b) / _litreErrors.length;

  /// Mean absolute percentage error.
  double? get mapePercent => _signedRelative.isEmpty
      ? null
      : _signedRelative.map((v) => v.abs()).reduce((a, b) => a + b) /
          _signedRelative.length *
          100;

  /// Signed bias — the sign matters: a consistently high estimate is a
  /// different defect from a noisy one, and averaging the absolutes
  /// hides it.
  double? get biasPercent => _signedRelative.isEmpty
      ? null
      : _signedRelative.reduce((a, b) => a + b) /
          _signedRelative.length *
          100;
}

/// Load every trace under [dir].
///
/// A trace is `<name>.summary.json` beside `<name>.samples.ndjson` — the
/// two canonical encodings the app already writes (`tripSummaryToJson`
/// and one `sampleToJson` per line, the shape
/// `parseActiveTripWalFile` reads). Reusing them means a recording can
/// become a fixture without a conversion step.
List<ReplayTrace> loadCorpus(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return const [];
  final traces = <ReplayTrace>[];
  final entries = directory.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in entries) {
    if (!file.path.endsWith('.summary.json')) continue;
    final name =
        file.uri.pathSegments.last.replaceAll('.summary.json', '');
    final samplesFile = File('$dir/$name.samples.ndjson');
    if (!samplesFile.existsSync()) continue;

    Map<String, dynamic> summary;
    try {
      summary = (jsonDecode(file.readAsStringSync()) as Map)
          .cast<String, dynamic>();
    } catch (_) {
      continue; // a corpus entry that does not parse is not a trace
    }

    final samples = <Map<String, dynamic>>[];
    for (final line in samplesFile.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      try {
        samples.add((jsonDecode(line) as Map).cast<String, dynamic>());
      } catch (_) {
        // Same rule as the WAL parser: a torn line is expected once per
        // hard kill, and skipping it keeps every other sample.
      }
    }
    traces.add(ReplayTrace(name: name, summary: summary, samples: samples));
  }
  return traces;
}

/// The markdown report.
String buildReplayReport({String root = '.', String? corpusDir}) {
  final dir = corpusDir ?? '$root/$kDefaultCorpusDir';
  final traces = loadCorpus(dir);
  final out = StringBuffer()
    ..writeln('# Consumption replay report')
    ..writeln()
    ..writeln('Corpus: `$dir`')
    ..writeln();

  if (traces.isEmpty) {
    out
      ..writeln('**No traces.** The harness is ready; the corpus is not.')
      ..writeln()
      ..writeln('#4231 requires *real* recordings — native fuel-rate, MAF,')
      ..writeln('speed-density, GPS-only and mixed coverage, each with a')
      ..writeln('full-to-full fill for truth. See the corpus README for the')
      ..writeln('format and the drop-in procedure.');
    return out.toString();
  }

  final leaking = traces.where((t) => t.carriesRawLocation).toList();
  if (leaking.isNotEmpty) {
    out
      ..writeln('## ⚠ Anonymisation failed')
      ..writeln()
      ..writeln('These traces still carry absolute coordinates and must not')
      ..writeln('be committed (#4231: location removed or offset *before*')
      ..writeln('commit):')
      ..writeln();
    for (final t in leaking) {
      out.writeln('- `${t.name}`');
    }
    out.writeln();
  }

  final buckets = {
    for (final c in ReplaySourceClass.values) c: ReplayBucket(c),
  };
  final skipped = <String>[];
  // #4232 — the fuzzy engine over the SAME eligible traces, side by side.
  final fuzzyBuckets = {
    for (final c in ReplaySourceClass.values) c: ReplayBucket(c),
  };
  final fuzzySkipped = <String>[];

  for (final trace in traces) {
    final bucket = buckets[trace.sourceClass]!;
    final reason = trace.ineligibleReason;
    if (reason != null) {
      bucket.ineligible++;
      skipped.add('`${trace.name}` (${trace.sourceClass.name}) — $reason');
      continue;
    }
    final fuzzy = replayFuzzy(trace.samples);
    final fuzzyReason = fuzzy.incompleteReason;
    if (fuzzyReason == null) {
      fuzzyBuckets[trace.sourceClass]!
          .add(truth: trace.truthLitres!, predicted: fuzzy.litres);
    } else {
      fuzzyBuckets[trace.sourceClass]!.ineligible++;
      fuzzySkipped
          .add('`${trace.name}` (${trace.sourceClass.name}) — $fuzzyReason');
    }
    final shipped = trace.shippedLitres;
    if (shipped == null) {
      bucket.ineligible++;
      skipped.add('`${trace.name}` (${trace.sourceClass.name}) — '
          'no shipped figure to compare');
      continue;
    }
    bucket.add(truth: trace.truthLitres!, predicted: shipped);
  }

  out
    ..writeln('## Error by source class')
    ..writeln()
    ..writeln('| source class | traces | ineligible | MAE (L) | MAPE | bias |')
    ..writeln('|---|---:|---:|---:|---:|---:|');
  for (final c in ReplaySourceClass.values) {
    final b = buckets[c]!;
    if (b.traces == 0 && b.ineligible == 0) continue;
    out.writeln('| ${c.name} | ${b.traces} | ${b.ineligible} '
        '| ${_fmt(b.maeLitres)} | ${_pct(b.mapePercent)} '
        '| ${_pct(b.biasPercent)} |');
  }
  out.writeln();

  _writeFuzzySection(out, fuzzyBuckets, fuzzySkipped);

  if (skipped.isNotEmpty) {
    out
      ..writeln('## Traces excluded from error, and why')
      ..writeln();
    for (final s in skipped) {
      out.writeln('- $s');
    }
    out.writeln();
  }

  return out.toString();
}

/// The fuzzy engine's table (#4232). Read-only reporting like the rest:
/// it never gates anything.
void _writeFuzzySection(
  StringBuffer out,
  Map<ReplaySourceClass, ReplayBucket> buckets,
  List<String> skipped,
) {
  final version = const FuzzyConsumptionEngine().version;
  out
    ..writeln('## Fuzzy engine (#4232), same eligible traces')
    ..writeln()
    ..writeln('Model ${version.model}, rules ${version.rules}. The shipped')
    ..writeln('rule base is neutral (multiplier 1, residual 0) until it is')
    ..writeln('fitted on real native-fuel-rate traces, so this integrates the')
    ..writeln('per-tick native / physics rates the engine passes through.')
    ..writeln()
    ..writeln('| source class | traces | not replayable | MAE (L) | MAPE '
        '| bias |')
    ..writeln('|---|---:|---:|---:|---:|---:|');
  for (final c in ReplaySourceClass.values) {
    final b = buckets[c]!;
    if (b.traces == 0 && b.ineligible == 0) continue;
    out.writeln('| ${c.name} | ${b.traces} | ${b.ineligible} '
        '| ${_fmt(b.maeLitres)} | ${_pct(b.mapePercent)} '
        '| ${_pct(b.biasPercent)} |');
  }
  out.writeln();
  if (skipped.isEmpty) return;
  out
    ..writeln('Not replayable through the engine:')
    ..writeln();
  for (final s in skipped) {
    out.writeln('- $s');
  }
  out.writeln();
}

String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(3);
String _pct(double? v) =>
    v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)} %';

void main(List<String> args) {
  String? corpus;
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == '--corpus') corpus = args[i + 1];
  }
  stdout.write(buildReplayReport(corpusDir: corpus));
}
