import 'package:xml/xml.dart';

import '../trip_history_repository.dart';

/// Builds a GPX 1.1 document from a single [TripHistoryEntry].
///
/// Emits one `<trk>` with one `<trkseg>` containing every persisted
/// sample whose `latitude` and `longitude` are non-null. Samples
/// without a GPS fix are skipped silently — they would render as a
/// teleport in any consuming tool. Altitude is included as `<ele>`
/// when present.
///
/// Returns the full XML document as a UTF-8 string suitable for
/// writing to a `.gpx` file or handing to the OS share sheet.
String buildGpxXml(
  TripHistoryEntry entry, {
  String creator = 'tankstellen',
  String? appVersion,
}) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  final creatorAttr = appVersion == null ? creator : '$creator $appVersion';
  builder.element(
    'gpx',
    attributes: <String, String>{
      'version': '1.1',
      'creator': creatorAttr,
      'xmlns': 'http://www.topografix.com/GPX/1/1',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation':
          'http://www.topografix.com/GPX/1/1 '
              'http://www.topografix.com/GPX/1/1/gpx.xsd',
    },
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
        builder.element('trkseg', nest: () {
          for (final s in entry.samples) {
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
            });
          }
        });
      });
    },
  );
  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}

/// Builds a GPX 1.1 document aggregating multiple trips. Each
/// [TripHistoryEntry] becomes its own `<trk>` element so consuming
/// tools can render them as distinct tracks.
String buildAggregateGpxXml(
  Iterable<TripHistoryEntry> entries, {
  String creator = 'tankstellen',
  String? appVersion,
}) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  final creatorAttr = appVersion == null ? creator : '$creator $appVersion';
  builder.element(
    'gpx',
    attributes: <String, String>{
      'version': '1.1',
      'creator': creatorAttr,
      'xmlns': 'http://www.topografix.com/GPX/1/1',
      'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation':
          'http://www.topografix.com/GPX/1/1 '
              'http://www.topografix.com/GPX/1/1/gpx.xsd',
    },
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
          builder.element('trkseg', nest: () {
            for (final s in entry.samples) {
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
              });
            }
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

