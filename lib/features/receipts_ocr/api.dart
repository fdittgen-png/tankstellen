// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `receipts_ocr` feature (#3743, epic item 1).
///
/// Extracted from the `consumption` mega-feature (the refile of the
/// half-done #3136): receipt parsing (spatial + brand-layout +
/// e-receipt), the shared-receipt intent pipeline and the bad-scan
/// reporting surfaces. (#3765 removed the pump-display OCR capture.)
///
/// Cross-feature consumers must import THIS file — never a path under
/// `data/`, `providers/` or `presentation/` of this feature. Enforced by
/// `test/lint/feature_boundary_test.dart` (epic #3129). The export list
/// is the contract measured at extraction time — it should only ever
/// SHRINK.
library;

export 'data/ereceipt/ereceipt_text_parser.dart';
export 'data/ocr/ocr_trace_package.dart';
export 'data/ocr/ocr_trace_recorder.dart';
export 'data/ocr/ocr_trace_serializer.dart';
export 'data/ocr/pump_ocr_config.dart';
export 'data/receipt_parser.dart';
export 'data/receipt_scan_service.dart';
export 'presentation/widgets/bad_scan_report_sheet.dart';
export 'presentation/widgets/ocr_block_overlay_painter.dart';
export 'presentation/widgets/ocr_trace_steps_panel.dart';
export 'presentation/widgets/share_receipt_listener.dart';
export 'providers/pending_shared_receipt_provider.dart';
export 'providers/pending_shared_receipt_text_provider.dart';
