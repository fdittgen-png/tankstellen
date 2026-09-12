// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The app's toolbar height, everywhere — `AppBar` through the theme and
/// every `SliverAppBar` explicitly (#4082). Material's 56 dp spent a
/// status-bar-height gap plus a tall toolbar above content on every
/// screen; 48 dp keeps the touch targets and gives the row back.
const double kAppToolbarHeight = 48;
