// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// What kind of payload an inbound OS share carried (#2735, GMS-free
/// rewrite). The native [ShareIntentChannel] classifies each `EXTRA_STREAM`
/// item by MIME / extension and `EXTRA_TEXT` as text, so the Dart handler
/// never re-sniffs file types.
enum SharedReceiptItemKind {
  /// A bitmap (`image/*`) copied into the app cache — routed through receipt
  /// photo OCR.
  image,

  /// A PDF (`application/pdf`) copied into the app cache — rasterised, then
  /// routed through the same OCR path as an image (#2737).
  pdf,

  /// Plain text (`EXTRA_TEXT`, or a shared `text/*` stream) — routed through
  /// the pure-Dart e-receipt text parser (#2838).
  text,

  /// Anything else (video / arbitrary file) — genuinely unsupported.
  file,
}

/// One attachment from an inbound share. Exactly one of [path] / [text] is
/// populated, keyed by [kind]: file-backed items ([image]/[pdf]/[file]) carry
/// a cache [path]; a [text] item carries the shared [text] body.
@immutable
class SharedReceiptItem {
  final SharedReceiptItemKind kind;

  /// Cache path for a file-backed item (image / pdf / file), else `null`.
  final String? path;

  /// Shared body for a [SharedReceiptItemKind.text] item, else `null`.
  final String? text;

  const SharedReceiptItem({required this.kind, this.path, this.text});

  const SharedReceiptItem.image(String this.path)
      : kind = SharedReceiptItemKind.image,
        text = null;

  const SharedReceiptItem.pdf(String this.path)
      : kind = SharedReceiptItemKind.pdf,
        text = null;

  const SharedReceiptItem.text(String this.text)
      : kind = SharedReceiptItemKind.text,
        path = null;

  const SharedReceiptItem.file(String this.path)
      : kind = SharedReceiptItemKind.file,
        text = null;

  /// Decodes one item from the platform-channel map. Returns `null` for a
  /// malformed entry so a single bad attachment never sinks the whole share.
  static SharedReceiptItem? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final kindStr = raw['kind'];
    final path = raw['path'];
    final text = raw['text'];
    switch (kindStr) {
      case 'image':
        return path is String && path.isNotEmpty
            ? SharedReceiptItem.image(path)
            : null;
      case 'pdf':
        return path is String && path.isNotEmpty
            ? SharedReceiptItem.pdf(path)
            : null;
      case 'text':
        return text is String && text.isNotEmpty
            ? SharedReceiptItem.text(text)
            : null;
      case 'file':
        return path is String && path.isNotEmpty
            ? SharedReceiptItem.file(path)
            : null;
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SharedReceiptItem &&
      other.kind == kind &&
      other.path == path &&
      other.text == text;

  @override
  int get hashCode => Object.hash(kind, path, text);
}

/// A decoded inbound OS share — the GMS-free in-repo analogue of
/// `share_handler`'s `SharedMedia`. Carries the attachments the native
/// receiver resolved from an `ACTION_SEND` / `ACTION_SEND_MULTIPLE` intent.
///
/// Optionally carries the device's [countryCode] (resolved natively from the
/// active locale) so the text parser reads amounts in the right currency
/// without a Dart-side lookup. `null` when unavailable — the parser then
/// defaults to EUR.
@immutable
class SharedReceiptIntent {
  final List<SharedReceiptItem> items;
  final String? countryCode;

  const SharedReceiptIntent({required this.items, this.countryCode});

  bool get isEmpty => items.isEmpty;

  /// Decodes the platform-channel payload (a `{items: [...], country: "..."}`
  /// map). Returns `null` for a null / non-map payload; drops malformed
  /// items individually.
  static SharedReceiptIntent? fromPlatform(Object? raw) {
    if (raw is! Map) return null;
    final rawItems = raw['items'];
    if (rawItems is! List) return null;
    final items = rawItems
        .map(SharedReceiptItem.fromMap)
        .whereType<SharedReceiptItem>()
        .toList(growable: false);
    if (items.isEmpty) return null;
    final country = raw['country'];
    return SharedReceiptIntent(
      items: items,
      countryCode: country is String && country.isNotEmpty ? country : null,
    );
  }
}
