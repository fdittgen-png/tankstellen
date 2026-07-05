// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Libre / F-Droid no-op stub for `google_mlkit_commons` (#3490, epic #3473).
///
/// Provides only the surface the app compiles against — [InputImage] with the
/// `fromFilePath` factory the ML Kit OCR engine constructs. It carries no
/// native code and is never reached at runtime on libre (the OCR factory
/// selects `NoopOcrTextEngine` when `AppFlavor.isLibre`), so the whole ML Kit
/// text-recognition path folds away and its `com.google.mlkit.*` references
/// never enter the fdroid dex.
library;

/// No-op stand-in for ML Kit's `InputImage`. Holds just the file path so the
/// [InputImage.fromFilePath] call in the (never-selected) ML Kit engine
/// compiles on the libre build.
class InputImage {
  const InputImage._(this.filePath);

  /// The image path the ML Kit engine would have recognized.
  final String? filePath;

  /// Mirrors `InputImage.fromFilePath` — the only factory the app uses.
  factory InputImage.fromFilePath(String path) => InputImage._(path);
}
