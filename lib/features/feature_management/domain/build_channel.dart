// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The release channel a running build belongs to (epic #1670).
///
/// Two channels:
/// - [production] — the public store build (App Store / Play production
///   track).
/// - [beta] — any pre-release build (TestFlight, Play internal / closed
///   tracks, local debug runs).
///
/// A build resolves its channel at compile time from
/// `--dart-define=CHANNEL=beta|production`, baked by CI / fastlane. When
/// the define is absent the channel is assumed to be [production]. The
/// live resolver is wired in #1674; this enum is the type the
/// feature-management model is keyed on (#1673).
enum BuildChannel { production, beta }
