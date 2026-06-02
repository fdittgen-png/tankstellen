// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:xml/xml.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/lessons/driving_lesson.dart';
import '../../domain/trip_recorder.dart';
import '../lessons/driving_lesson_registry.dart';
import '../trip_history_repository.dart';

/// Namespace URI for the tankstellen GPX extensions (#2251). Carrying
/// the post-trip lessons inside a vendor namespace keeps the document
/// schema-valid — GPX 1.1 explicitly allows arbitrary namespaced
/// children inside `<extensions>`. The prefix `tankstellen` is declared
/// on the `<gpx>` root and used on every lesson element.
// i18n-ignore: namespace URI, not user-facing text
const String tankstellenGpxNamespace = 'https://tankstellen.de/gpx/1';

/// Namespace URI for the de-facto Garmin TrackPointExtension v1 (#2652).
/// Consuming tools (Garmin BaseCamp, Strava, GPSBabel) read per-trkpt
/// `<gpxtpx:speed>` / `<gpxtpx:course>` from this namespace. Declared on
/// the `<gpx>` root only when at least one sample carries a bearing, so a
/// no-heading trip stays byte-identical to the pre-#2652 document.
// i18n-ignore: namespace URI, not user-facing text
const String garminTrackPointExtensionNamespace =
    'http://www.garmin.com/xmlschemas/TrackPointExtension/v1';

/// Builds a GPX 1.1 document from a single [TripHistoryEntry].
///
/// Emits one `<trk>` with one `<trkseg>` containing every persisted
/// sample whose `latitude` and `longitude` are non-null. Samples
/// without a GPS fix are skipped silently — they would render as a
/// teleport in any consuming tool. Altitude is included as `<ele>`
/// when present.
///
/// When [l] is supplied the computed post-trip driving lessons (#2251)
/// for the trip are embedded in the track's `<extensions>` as a
/// namespaced `<tankstellen:lessons>` block — one `<tankstellen:lesson>`
/// per firing lesson carrying its `id`, `value`, `impact`, and a
/// localized `<tankstellen:message>`. The block is omitted entirely when
/// no lessons fire or when [l] is null (no localizer to resolve the
/// messages). Lessons are computed via [registry], defaulting to the
/// standard production set.
///
/// Returns the full XML document as a UTF-8 string suitable for
/// writing to a `.gpx` file or handing to the OS share sheet.
String buildGpxXml(
  TripHistoryEntry entry, {
  String creator = 'tankstellen',
  String? appVersion,
  AppLocalizations? l,
  DrivingLessonRegistry? registry,
}) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  final creatorAttr = appVersion == null ? creator : '$creator $appVersion';
  final lessons = _lessonsFor(entry, l, registry);
  builder.element(
    'gpx',
    attributes: _gpxRootAttributes(
      creatorAttr,
      includeLessonsNs: lessons.isNotEmpty,
      includeTrackPointExtensionNs: _anyBearing(entry.samples),
    ),
    nest: () {
      builder.element('metadata', nest: () {
        builder.element('name', nest: () {
          builder.text(_trackName(entry));
        });
        final start = entry.summary.startedAt;
        if (start != null) {
          builder.element('time', nest: () {
            builder.text(start.toUtc().toIso8601String());
          });
        }
      });
      builder.element('trk', nest: () {
        builder.element('name', nest: () {
          builder.text(_trackName(entry));
        });
        _appendLessonsExtensions(builder, lessons);
        builder.element('trkseg', nest: () {
          _appendTrkpts(builder, entry.samples);
        });
      });
    },
  );
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}

/// Root `<gpx>` attributes. The tankstellen extensions namespace is
/// declared only when at least one trk carries a lessons block, so a
/// lessons-free export is byte-identical to the pre-#2251 document.
Map<String, String> _gpxRootAttributes(
  String creatorAttr, {
  required bool includeLessonsNs,
  bool includeTrackPointExtensionNs = false,
}) {
  final attrs = <String, String>{
    'version': '1.1',
    'creator': creatorAttr,
    'xmlns': 'http://www.topografix.com/GPX/1/1',
    'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
    'xsi:schemaLocation': 'http://www.topografix.com/GPX/1/1 '
        'http://www.topografix.com/GPX/1/1/gpx.xsd',
  };
  if (includeLessonsNs) {
    attrs['xmlns:tankstellen'] = tankstellenGpxNamespace;
  }
  if (includeTrackPointExtensionNs) {
    attrs['xmlns:gpxtpx'] = garminTrackPointExtensionNamespace;
  }
  return attrs;
}

/// True when at least one sample carries a bearing, gating the
/// `xmlns:gpxtpx` root declaration (#2652) so a no-heading trip stays
/// byte-identical to the pre-#2652 document.
bool _anyBearing(Iterable<TripSample> samples) =>
    samples.any((s) => s.bearingDeg != null);

/// Appends one `<trkpt>` per GPS-fixed sample to the open `<trkseg>`.
/// Samples without a lat/lon fix are skipped (they would render as a
/// teleport). `<ele>` is emitted when altitude is present; a Garmin
/// `<extensions><gpxtpx:TrackPointExtension>` carrying `<gpxtpx:speed>`
/// (m/s — GPX uses SI) and `<gpxtpx:course>` (degrees) is emitted only
/// when the sample has a bearing (#2652), so a no-heading trip's output
/// is unchanged from before.
void _appendTrkpts(XmlBuilder builder, Iterable<TripSample> samples) {
  for (final s in samples) {
    final lat = s.latitude;
    final lon = s.longitude;
    if (lat == null || lon == null) continue;
    builder.element('trkpt', attributes: <String, String>{
      'lat': lat.toStringAsFixed(7),
      'lon': lon.toStringAsFixed(7),
    }, nest: () {
      final alt = s.altitudeM;
      if (alt != null) {
        builder.element('ele', nest: () {
          builder.text(alt.toStringAsFixed(1));
        });
      }
      builder.element('time', nest: () {
        builder.text(s.timestamp.toUtc().toIso8601String());
      });
      final bearing = s.bearingDeg;
      if (bearing != null) {
        builder.element('extensions', nest: () {
          builder.element('gpxtpx:TrackPointExtension', nest: () {
            // GPX speed is metres/second; trip samples store km/h.
            builder.element('gpxtpx:speed', nest: () {
              builder.text((s.speedKmh / 3.6).toStringAsFixed(3));
            });
            builder.element('gpxtpx:course', nest: () {
              builder.text(bearing.toStringAsFixed(1));
            });
          });
        });
      }
    });
  }
}

/// Computes the post-trip lessons for [entry] via [registry] (defaulting
/// to the standard set). Returns an empty list when [l] is null — there
/// is no localizer to resolve the lesson messages, so the GPX simply
/// omits the block.
List<DrivingLesson> _lessonsFor(
  TripHistoryEntry entry,
  AppLocalizations? l,
  DrivingLessonRegistry? registry,
) {
  if (l == null) return const [];
  final reg = registry ?? DrivingLessonRegistry.standard();
  return reg.evaluate(entry.summary, entry.samples, l);
}

/// Appends a `<extensions>` block carrying the trip's driving lessons to
/// the open `<trk>` element. No-op when [lessons] is empty so the
/// document is unchanged for trips with no firing lessons (and for the
/// no-localizer path).
void _appendLessonsExtensions(XmlBuilder builder, List<DrivingLesson> lessons) {
  if (lessons.isEmpty) return;
  builder.element('extensions', nest: () {
    builder.element('tankstellen:lessons', nest: () {
      for (final lesson in lessons) {
        builder.element('tankstellen:lesson', attributes: <String, String>{
          'id': lesson.id,
          'value': lesson.metricValue.toStringAsFixed(3),
          'impact': lesson.impact.toStringAsFixed(3),
        }, nest: () {
          builder.element('tankstellen:title', nest: () {
            builder.text(lesson.title);
          });
          if (lesson.advice.isNotEmpty) {
            builder.element('tankstellen:message', nest: () {
              builder.text(lesson.advice);
            });
          }
        });
      }
    });
  });
}

/// Builds a GPX 1.1 document aggregating multiple trips. Each
/// [TripHistoryEntry] becomes its own `<trk>` element so consuming
/// tools can render them as distinct tracks.
///
/// When [l] is supplied each track embeds its own post-trip lessons
/// block (#2251), identical in shape to [buildGpxXml]'s.
String buildAggregateGpxXml(
  Iterable<TripHistoryEntry> entries, {
  String creator = 'tankstellen',
  String? appVersion,
  AppLocalizations? l,
  DrivingLessonRegistry? registry,
}) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  final creatorAttr = appVersion == null ? creator : '$creator $appVersion';
  final lessonsByEntry = <TripHistoryEntry, List<DrivingLesson>>{
    for (final entry in entries) entry: _lessonsFor(entry, l, registry),
  };
  final anyLessons = lessonsByEntry.values.any((v) => v.isNotEmpty);
  final anyBearing = entries.any((e) => _anyBearing(e.samples));
  builder.element(
    'gpx',
    attributes: _gpxRootAttributes(
      creatorAttr,
      includeLessonsNs: anyLessons,
      includeTrackPointExtensionNs: anyBearing,
    ),
    nest: () {
      builder.element('metadata', nest: () {
        builder.element('name', nest: () {
          builder.text('tankstellen export');
        });
      });
      for (final entry in entries) {
        builder.element('trk', nest: () {
          builder.element('name', nest: () {
            builder.text(_trackName(entry));
          });
          _appendLessonsExtensions(
            builder,
            lessonsByEntry[entry] ?? const [],
          );
          builder.element('trkseg', nest: () {
            _appendTrkpts(builder, entry.samples);
          });
        });
      }
    },
  );
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}

/// Number of samples in [entry] whose GPS fix is non-null. Useful for
/// callers that want to decide whether a GPX export would be empty
/// before offering the option to the user.
int countGpsFixes(TripHistoryEntry entry) {
  var n = 0;
  for (final s in entry.samples) {
    if (s.latitude != null && s.longitude != null) n++;
  }
  return n;
}

String _trackName(TripHistoryEntry entry) {
  final start = entry.summary.startedAt;
  if (start == null) return 'tankstellen trajet ${entry.id}';
  final y = start.year.toString();
  final m = start.month.toString().padLeft(2, '0');
  final d = start.day.toString().padLeft(2, '0');
  final h = start.hour.toString().padLeft(2, '0');
  final min = start.minute.toString().padLeft(2, '0');
  return 'tankstellen $y-$m-$d $h:$min';
}

/// Suggested filename (no extension dot prefix) for a single-trip GPX
/// export. Caller is responsible for path joining + the `.gpx`
/// suffix. Returns a slug-safe ASCII string.
String gpxFileNameFor(TripHistoryEntry entry) {
  final start = entry.summary.startedAt;
  if (start == null) return 'tankstellen-trajet-${entry.id}.gpx';
  final y = start.year.toString();
  final m = start.month.toString().padLeft(2, '0');
  final d = start.day.toString().padLeft(2, '0');
  final h = start.hour.toString().padLeft(2, '0');
  final min = start.minute.toString().padLeft(2, '0');
  return 'tankstellen-trajet-$y$m${d}T$h$min.gpx';
}

