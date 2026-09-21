// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_meta.freezed.dart';
part 'document_meta.g.dart';

/// What kind of document an expense was built from (#4215).
enum FleetDocumentType {
  /// A photograph of a paper receipt.
  receiptPhoto,

  /// A PDF receipt (rasterised for OCR, or read from its text layer).
  receiptPdf,

  /// Digital receipt text — an e-mail body, an SMS, a PDF text layer.
  eReceiptText,

  /// A structured electronic invoice.
  structuredInvoice,
}

/// Which retention rule governs a document (#4215, ADR 0025 D9).
///
/// The number of years is deployment configuration
/// (`fleet_policies.data`), never a constant in this codebase — a legal
/// retention period is a legal conclusion, and the app does not draw
/// one. This enum names WHICH configured key applies.
enum DocumentRetentionClass {
  /// D9 `retention.expensesYears` — an accounting document.
  accountingDocument,

  /// D9 `retention.attributionEventsMonths` — evidence for why a
  /// vehicle was chosen, not an accounting record.
  attributionEvidence,

  /// No retention rule configured: the document lives until the user
  /// deletes it. The honest default — not "keep forever".
  userManaged,
}

/// Where a document is in its deletion lifecycle (#4215).
///
/// Deletion is a state, not an event: an accounting document under a
/// retention rule can be *requested* gone long before it may be
/// removed, and the request must survive in the meantime.
enum DocumentDeletionStatus {
  /// Present and readable.
  active,

  /// Deletion requested; the retention rule has not released it yet.
  pendingDeletion,

  /// The bytes are gone; this row remains as the tombstone.
  deleted,
}

/// The metadata of one stored source document — and nothing else
/// (#4215, ADR 0025 "what never leaves the device").
///
/// **There is deliberately no byte field, no path, no base64 and no
/// thumbnail on this type.** The image lives in private object storage
/// under [objectKey]; everything that travels — a log line, an OCR
/// trace, a crash report, a sync row, the GDPR export index — travels
/// as this metadata. A receipt can carry a full card number, a name and
/// an address; the one way to guarantee it never reaches a trace is for
/// the domain object not to be able to hold it.
///
/// [sha256] is what makes the same receipt scanned twice recognisable
/// as the same receipt — the reconciler's first duplicate test — while
/// revealing nothing about the content.
@freezed
abstract class DocumentMeta with _$DocumentMeta {
  const factory DocumentMeta({
    required String id,

    /// Tenancy key — the organisation the document belongs to.
    required String orgId,

    /// The employee who captured or imported it.
    required String ownerId,

    required FleetDocumentType type,

    /// Key in PRIVATE object storage. Never a public URL: ADR 0025
    /// forbids a publicly-addressable receipt.
    required String objectKey,

    /// Lower-case hex SHA-256 of the stored bytes. The duplicate key.
    required String sha256,

    /// When the document was captured / imported — UTC, injected clock.
    required DateTime capturedAt,

    /// Which engine read it (`mlkit`, `none` for a structured invoice).
    String? ocrEngine,

    /// That engine's version, so a re-read can be compared honestly.
    String? ocrVersion,

    /// Extraction confidence in [0, 1]; null when nothing was read.
    double? confidence,

    @Default(DocumentRetentionClass.userManaged)
    DocumentRetentionClass retentionClass,

    @Default(DocumentDeletionStatus.active)
    DocumentDeletionStatus deletionStatus,
  }) = _DocumentMeta;

  factory DocumentMeta.fromJson(Map<String, dynamic> json) =>
      _$DocumentMetaFromJson(json);
}

/// The questions a caller asks about a document without knowing the
/// retention vocabulary.
extension DocumentMetaX on DocumentMeta {
  /// The bytes are still supposed to exist.
  bool get isReadable => deletionStatus == DocumentDeletionStatus.active;

  /// A deletion was asked for and has not been honoured yet — the
  /// state a privacy screen must be able to show, rather than
  /// pretending the document is simply gone.
  bool get awaitsDeletion =>
      deletionStatus == DocumentDeletionStatus.pendingDeletion;

  /// A retention period configured by the deployment governs this
  /// document, so the user cannot simply delete it on request.
  bool get isRetentionGoverned =>
      retentionClass != DocumentRetentionClass.userManaged;
}
