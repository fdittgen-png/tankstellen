// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import '../../../../core/logging/error_logger.dart';

/// #3612 (2026-07-26 audit, wave 2) — inbound-share ingestion caps.
///
/// An `ACTION_SEND` / `ACTION_SEND_MULTIPLE` payload is attacker-shaped
/// input: any app on the device can hand us an arbitrary file, and the
/// Dart side feeds it straight into the OCR / PDF-rasterise pipeline.
/// Before a shared file enters that pipeline it must pass
/// [isAcceptableSharePayload]:
///
///   * **size** — at most [kMaxSharePayloadBytes] (16 MB). A receipt
///     photo is single-digit MB; anything larger is either not a receipt
///     or a memory-exhaustion attempt.
///   * **extension** — one of [kAcceptedShareExtensions]. The native
///     receivers only ever cache `.jpg` / `.png` / `.pdf` names
///     (`ShareIntentChannel.kt`, `ShareViewController.swift`), so this is
///     defense-in-depth against a payload that skipped the native
///     classifier.
///
/// The PDF page cap lives downstream in `ReceiptPdfRasterizer.maxPages`
/// (#2737) — the page count is only knowable after opening the document.
///
/// Rejection is silent by design: the payload is dropped and the reason
/// spooled via [errorLogger] by the caller — no snackbar, no new strings.

/// Hard cap on a shared file's size, in bytes (16 MB).
const int kMaxSharePayloadBytes = 16 * 1024 * 1024;

/// File extensions (lower-case, without the dot) a shared file may carry
/// to enter the receipt pipeline.
const Set<String> kAcceptedShareExtensions = {
  'jpg',
  'jpeg',
  'png',
  'webp',
  'pdf',
};

/// Pure acceptance predicate for one file-backed share payload.
///
/// [sizeBytes] is the file's on-disk size, or `null` when it could not
/// be determined (see [sharePayloadSizeBytes]). An unknown size passes
/// the size check: a file that cannot be stat-ed cannot be opened by the
/// OCR / rasterise step either, so it carries no decompression /
/// memory-exhaustion risk — while a determinable size is bounded strictly.
/// A zero/negative size is rejected: a 0-byte "receipt" is never valid.
///
/// Pure function of its inputs — no I/O — so it unit-tests without a
/// filesystem.
bool isAcceptableSharePayload({required int? sizeBytes, required String path}) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return false;
  final ext = path.substring(dot + 1).toLowerCase();
  if (!kAcceptedShareExtensions.contains(ext)) return false;
  if (sizeBytes != null &&
      (sizeBytes <= 0 || sizeBytes > kMaxSharePayloadBytes)) {
    return false;
  }
  return true;
}

/// Best-effort size probe for [isAcceptableSharePayload]. Returns the
/// file's length in bytes, or `null` when the file is missing or
/// unreadable (the guard treats `null` as "unknown", see above).
/// Never throws.
int? sharePayloadSizeBytes(String path) {
  try {
    return File(path).lengthSync();
  } catch (e, st) {
    // Missing / unreadable cache file — the share was already broken
    // before the guard ran. Spooled for triage, then treated as unknown.
    unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
      'where': 'sharePayloadSizeBytes',
    }));
    return null;
  }
}
