// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// The ONE share-sheet seam shape (#1301 precedent). Production sends
/// [ShareParams] straight to `SharePlus.instance.share`; widget tests
/// substitute a fake to assert the outgoing payload without launching
/// the real OS share sheet. Every feature-local
/// `debug<Feature>ShareSinkOverride` global is typed with this alias
/// instead of re-declaring the function shape.
typedef ShareSink = Future<void> Function(ShareParams params);

/// The ONE temporary-directory seam shape for share flows that stage a
/// file before handing it to the OS share sheet. Returns a [Directory]
/// the flow is allowed to write into; tests substitute a sandbox dir.
typedef ShareTempDirectoryProvider = Future<Directory> Function();
