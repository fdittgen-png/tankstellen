// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `moderation` feature (#3871, Epic #3865).
///
/// Community-content moderation SURFACES: the state itself (block list,
/// reported ids) lives in `lib/core/moderation/` so every feature that
/// renders another user's content can filter against it. This feature
/// hosts the user-facing management UI — currently the Privacy
/// Dashboard's "Blocked users" card with its Unblock action.
///
/// Cross-feature consumers must import THIS file — never a path under
/// `presentation/` of this feature. Enforced by
/// `test/lint/feature_boundary_test.dart` (epic #3129).
library;

export 'presentation/widgets/blocked_authors_section.dart';
