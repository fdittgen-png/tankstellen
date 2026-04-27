import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hook for the share-sheet handoff (#1189).
///
/// Production calls [SharePlus.instance.share] directly; tests substitute
/// a fake via [debugShareSinkOverride] so widget tests can assert on the
/// outgoing [ShareParams] without launching the OS share sheet.
typedef TripShareSink = Future<void> Function(ShareParams params);

/// Test-only override for the share sink used by [shareTripAsImage].
///
/// Set inside a widget test (and remember to clear it in `addTearDown`)
/// so the renderer routes [SharePlus.instance.share] through a fake.
@visibleForTesting
TripShareSink? debugShareSinkOverride;

/// Hook for the temporary-directory lookup used by [shareTripAsImage].
///
/// Production calls [getTemporaryDirectory] from `path_provider`; tests
/// substitute a fake via [debugTemporaryDirectoryOverride] so the
/// generated PNG is written into the test sandbox instead of the real
/// platform temp folder.
typedef TripShareTempDirectoryProvider = Future<Directory> Function();

/// Test-only override for the temp-directory lookup used by
/// [shareTripAsImage]. Returns a [Directory] the renderer is allowed to
/// write into.
@visibleForTesting
TripShareTempDirectoryProvider? debugTemporaryDirectoryOverride;

/// Renders the widget identified by [boundaryKey] to a PNG and hands it
/// to the OS share sheet via `share_plus` (#1189).
///
/// The caller is responsible for wrapping the visible report content in
/// a [RepaintBoundary] keyed by [boundaryKey] — the renderer pulls
/// [RenderRepaintBoundary] out of that boundary's render object and
/// rasterises it at [pixelRatio] (default 3.0 — high enough that the
/// shared image looks crisp on a Retina-class messaging app preview).
///
/// The generated PNG is written to a temporary file
/// `<temp>/<fileNameStem>.png` and shared with [subject] as the share
/// sheet's caption / message text.
///
/// Throws when the boundary is missing or its render object is not a
/// [RenderRepaintBoundary]. Errors from [SharePlus] propagate to the
/// caller — wrap the call in your own try/catch and surface the failure
/// via a snackbar / error logger when a UI integration calls this.
Future<void> shareTripAsImage({
  required GlobalKey boundaryKey,
  required String subject,
  required String fileNameStem,
  double pixelRatio = 3.0,
}) async {
  final boundaryContext = boundaryKey.currentContext;
  if (boundaryContext == null) {
    throw StateError(
      'shareTripAsImage: boundary key has no currentContext — the '
      'RepaintBoundary is not mounted.',
    );
  }
  final renderObject = boundaryContext.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError(
      'shareTripAsImage: expected a RenderRepaintBoundary, got '
      '${renderObject.runtimeType}.',
    );
  }

  final image = await renderObject.toImage(pixelRatio: pixelRatio);
  final ByteData? byteData;
  try {
    byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  } finally {
    image.dispose();
  }
  if (byteData == null) {
    throw StateError('shareTripAsImage: PNG encoding returned null bytes.');
  }
  final bytes = byteData.buffer.asUint8List();

  final tempDirProvider =
      debugTemporaryDirectoryOverride ?? getTemporaryDirectory;
  final tempDir = await tempDirProvider();
  final filePath = '${tempDir.path}/$fileNameStem.png';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);

  final params = ShareParams(
    files: [XFile(filePath)],
    text: subject,
    subject: subject,
  );
  final sink = debugShareSinkOverride ?? _defaultShareSink;
  await sink(params);
}

Future<void> _defaultShareSink(ShareParams params) =>
    SharePlus.instance.share(params);
