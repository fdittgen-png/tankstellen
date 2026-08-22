// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The transaction-field vocabulary of an OCR'd fuel purchase (#2478).
///
/// Originally the label table of the pump-display extractor; #3765
/// removed that extractor, but the receipt spatial parser still keys
/// its per-field reads on this enum.
library;

/// Which transaction field a value belongs to.
enum PumpField { total, volume, pricePerLitre }
