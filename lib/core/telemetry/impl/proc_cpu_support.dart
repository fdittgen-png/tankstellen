// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

/// #3641 — whether this platform exposes the `/proc` CPU accounting the
/// background CPU watchdog samples. Android only: iOS/macOS ship no
/// readable `/proc`, and only Android kills apps on the background-CPU
/// limit the watchdog exists to explain. Platform dispatch lives here
/// (impl/, per #2350/#3163) so the watchdog itself stays shared code.
bool procCpuSupported() => !kIsWeb && Platform.isAndroid;
