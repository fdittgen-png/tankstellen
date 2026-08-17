// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Where Hive's box files live (#3747, item 3).
///
/// `Hive.initFlutter()` roots every box in the app **Documents**
/// directory. On iOS this app ships `UIFileSharingEnabled` +
/// `LSSupportsOpeningDocumentsInPlace` (wanted for user-facing exports),
/// which exposes the whole Documents directory in the Files app — so
/// every Hive box (favorites, settings, encrypted trip telemetry, …)
/// was user-copyable AND user-corruptible from outside the app. The fix
/// moves the database off the shared surface, NOT the plist keys:
/// on iOS Hive now roots in **Application Support** (never exposed via
/// file sharing), with a one-time move of the legacy Documents-dir box
/// files. Android and every other platform stay byte-identical
/// (`Hive.initFlutter()`).
///
/// This lives in `impl/` — the sanctioned seam for the `Platform.isIOS`
/// fork (see `test/lint/no_inline_platform_check_test.dart`).
class HiveDirectoryResolver {
  HiveDirectoryResolver._();

  /// Initialise Hive's base directory. Drop-in replacement for the
  /// `Hive.initFlutter()` call in `HiveBoxes.init` /
  /// `HiveIsolateBoxes.initInIsolate` — never throws beyond what
  /// `Hive.initFlutter()` itself could throw.
  static Future<void> initHive() async {
    if (!kIsWeb && Platform.isIOS) {
      await _initIos();
      return;
    }
    // Non-iOS: byte-identical to the previous behaviour.
    await Hive.initFlutter();
  }

  /// iOS: root Hive in Application Support, migrating legacy
  /// Documents-dir box files once. Any resolution failure falls back to
  /// the legacy `Hive.initFlutter()` Documents-dir behaviour, so a
  /// path_provider fault can never brick startup ON TOP of what the
  /// pre-#3747 code would have done.
  static Future<void> _initIos() async {
    // Mirrors Hive.initFlutter(), which path_provider needs.
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final support = await getApplicationSupportDirectory();
      final legacy = await getApplicationDocumentsDirectory();
      Hive.init(migrateAndResolve(legacy, support));
    } catch (e, st) { // ignore: unused_catch_stack
      debugPrint('HiveDirectoryResolver: iOS dir resolution failed ($e) '
          '— falling back to the legacy Documents dir.');
      await Hive.initFlutter();
    }
  }

  /// Resolves the directory Hive should run from, moving the legacy
  /// box files exactly once. **Never throws** — a failed migration
  /// rolls back and answers [legacyDir] so this launch runs fully from
  /// the still-intact legacy files and the next launch retries.
  ///
  /// Rules:
  ///  * [targetDir] already holds Hive files → use it (migration done,
  ///    or fresh data already lives there). Never move ON TOP of newer
  ///    data.
  ///  * no Hive files in [legacyDir] → fresh install, use [targetDir].
  ///  * otherwise MOVE each legacy `.hive` / `.hivec` file via a
  ///    same-volume rename (atomic per file — never copy-then-delete).
  ///    `.lock` files are left behind; Hive recreates them. On ANY move
  ///    failure every already-moved file is renamed back (best-effort)
  ///    and [legacyDir] is used, so the box set is never split across
  ///    two directories.
  ///
  /// A concurrent foreground/background race is benign: the second
  /// initialiser either sees the target populated (uses it) or the
  /// legacy files already gone (fresh-install path, also the target).
  ///
  /// [move] is the fault-injection seam for the never-throws test.
  @visibleForTesting
  static String migrateAndResolve(
    Directory legacyDir,
    Directory targetDir, {
    void Function(File file, String newPath)? move,
  }) {
    final doMove = move ?? (file, newPath) => file.renameSync(newPath);
    try {
      if (!targetDir.existsSync()) targetDir.createSync(recursive: true);
      if (_hiveFilesIn(targetDir).isNotEmpty) return targetDir.path;
      final legacyFiles =
          legacyDir.existsSync() ? _hiveFilesIn(legacyDir) : const <File>[];
      if (legacyFiles.isEmpty) return targetDir.path;

      final moved = <(File, String)>[];
      try {
        for (final file in legacyFiles) {
          final newPath = _join(targetDir.path, _baseName(file.path));
          doMove(file, newPath);
          moved.add((file, newPath));
        }
        debugPrint('HiveDirectoryResolver: moved ${moved.length} Hive box '
            'file(s) out of the file-sharing surface (#3747).');
        return targetDir.path;
      } catch (e, st) { // ignore: unused_catch_stack
        debugPrint('HiveDirectoryResolver: migration failed ($e) — '
            'rolling back to the legacy dir; will retry next launch.');
        for (final (original, newPath) in moved) {
          try {
            File(newPath).renameSync(original.path);
          } catch (e2, st2) { // ignore: unused_catch_stack
            // Same-volume rename-back failing is a hard disk fault; the
            // target-populated rule above makes the NEXT launch adopt
            // the target dir rather than losing the moved boxes.
            debugPrint('HiveDirectoryResolver: rollback of '
                '$newPath failed: $e2');
          }
        }
        return legacyDir.path;
      }
    } catch (e, st) { // ignore: unused_catch_stack
      debugPrint('HiveDirectoryResolver: directory probe failed ($e) — '
          'staying on the legacy dir.');
      return legacyDir.path;
    }
  }

  /// The Hive box files (`.hive` data + `.hivec` compaction remnants)
  /// directly inside [dir]. `.lock` files are ignored — Hive recreates
  /// them wherever it runs.
  static List<File> _hiveFilesIn(Directory dir) => [
        for (final entity in dir.listSync(followLinks: false))
          if (entity is File &&
              (entity.path.endsWith('.hive') ||
                  entity.path.endsWith('.hivec')))
            entity,
      ];

  static String _baseName(String path) =>
      path.split(Platform.pathSeparator).last;

  static String _join(String dir, String name) =>
      '$dir${Platform.pathSeparator}$name';
}
