// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/app_log.dart';
import '../logging/error_logger.dart';

/// What the box files on disk say about the key that has to read them
/// (#4341).
enum BoxKeyVerdict {
  /// Nothing on disk that this key cannot read: no box files, empty
  /// ones, plaintext ones (the pre-#1686 legacy boxes and the boxes that
  /// are never encrypted), or ciphertext written under this very key.
  consistent,

  /// Ciphertext written under a DIFFERENT key, and none under this one —
  /// a restore whose KeyStore key stayed on the old phone (#4118).
  keyLost,

  /// The directory could not be inspected, so nothing is known.
  unknown,
}

/// Reads the box files' own frames to decide whether a key fits them,
/// without opening a single box (#4341).
///
/// #4118 stopped a restored install on the launch that had to mint a new
/// key — but that launch had already WRITTEN the key. The next process
/// read it back, had no "minted this launch" flag, and opened the old
/// ciphertext under the wrong key, which Hive's crash recovery answers by
/// truncating the file. A per-process flag cannot carry a verdict across
/// processes; the files can, because they do not change until the user
/// resolves the state.
///
/// The evidence is Hive's frame checksum. Every frame ends in a CRC-32
/// whose seed is the cipher's key CRC — 0 for a plaintext frame
/// (`BinaryWriterImpl.writeFrame`). So the first frame of a file says,
/// read-only, whether it is plaintext, written under a given key, or
/// written under some other key.
///
/// Only a COMPLETE first frame counts. An empty file, or a torn first
/// write, holds nothing either key could recover, so it is no evidence.
abstract final class HiveBoxKeyProbe {
  /// The verdict for the `.hive` files directly in [hivePath] against
  /// [cipher] — null meaning "this install has no key".
  ///
  /// [BoxKeyVerdict.keyLost] needs at least one file of foreign
  /// ciphertext AND no file written under [cipher]. The second half keeps
  /// a single damaged first frame from being read as a lost key while
  /// every other box proves the key right.
  ///
  /// Never throws: an unknown [hivePath] or an unreadable file answers
  /// [BoxKeyVerdict.unknown], and the caller decides what that permits.
  ///
  /// ## Cost
  ///
  /// The CRC covers the whole first frame, so a file cannot be judged
  /// without reading all of it — and `datasets`, the trip history and
  /// `cache` can open with a multi-megabyte record (~100 ms at 5 MB).
  /// This runs before the first frame, again for the deferred boxes, in
  /// every background isolate and in cache recovery. So files are read
  /// SMALLEST FIRST and the scan stops at the first frame under the key:
  /// on an ordinary launch that is one small box, and the big ones are
  /// never read. The verdict does not depend on the order.
  ///
  /// [onRead] reports each first frame read and its byte count — the
  /// test seam that proves the large files are skipped.
  static BoxKeyVerdict inspect(
    String? hivePath,
    HiveAesCipher? cipher, {
    void Function(File file, int bytes)? onRead,
  }) {
    if (hivePath == null) return BoxKeyVerdict.unknown;
    try {
      final dir = Directory(hivePath);
      if (!dir.existsSync()) return BoxKeyVerdict.consistent;
      final keyCrc = cipher?.calculateKeyCrc();
      final boxes = [
        for (final entity in dir.listSync(followLinks: false))
          if (entity is File && entity.path.endsWith('.hive'))
            (file: entity, size: entity.lengthSync()),
      ]..sort((a, b) => a.size.compareTo(b.size));
      var foreign = false;
      for (final (:file, size: _) in boxes) {
        switch (_firstFrame(file, keyCrc, onRead)) {
          case _Frame.thisKey:
            return BoxKeyVerdict.consistent;
          case _Frame.foreign:
            foreign = true;
          case _Frame.none || _Frame.plaintext:
            break;
        }
      }
      return foreign ? BoxKeyVerdict.keyLost : BoxKeyVerdict.consistent;
    } catch (e, st) {
      log.warn('HiveBoxKeyProbe: box files could not be inspected',
          error: e, stack: st, layer: ErrorLayer.storage);
      return BoxKeyVerdict.unknown;
    }
  }

  static _Frame _firstFrame(
      File file, int? keyCrc, void Function(File, int)? onRead) {
    final raf = file.openSync();
    try {
      final size = raf.lengthSync();
      if (size < 8) return _Frame.none;
      final header = raf.readSync(4);
      final length =
          ByteData.sublistView(header).getUint32(0, Endian.little);
      // Hive reads a frame shorter than 8 bytes, or longer than the file,
      // as no frame at all.
      if (length < 8 || length > size) return _Frame.none;
      final frame = Uint8List(length)
        ..setRange(0, 4, header)
        ..setRange(4, length, raf.readSync(length - 4));
      onRead?.call(file, length);
      final body = Uint8List.sublistView(frame, 0, length - 4);
      final stored = ByteData.sublistView(frame)
          .getUint32(length - 4, Endian.little);
      if (getCrc32(body) == stored) return _Frame.plaintext;
      if (keyCrc != null && getCrc32(body, keyCrc) == stored) {
        return _Frame.thisKey;
      }
      return _Frame.foreign;
    } finally {
      raf.closeSync();
    }
  }
}

enum _Frame { none, plaintext, thisKey, foreign }
