<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0007: MIT license choice

**Status:** Superseded by [ADR 0028](0028-agpl-with-a-commercial-exception.md)
**Date:** 2024-06-01
**Superseded:** 2026-09-20

> This decision no longer holds. Sparkilo is AGPL-3.0-or-later, and the
> "GPL-licensed dependencies are prohibited" rule below is reversed —
> the constraint is now AGPL-compatibility outbound. The document is
> kept because ADR 0028 reverses it knowingly and the reasoning it
> reverses has to remain readable; in particular, this ADR named
> "no protection against proprietary forks" as the accepted trade-off,
> and that is precisely what changed. Everything released before
> 2026-09-20 remains MIT and can be forked on those terms for ever.

## Context

The project is open-source and intended to remain freely usable, modifiable,
and distributable. Choosing a license affects which dependencies can be
included, how others can use the code, and whether commercial forks are
permitted.

The main license families considered were:

- **Permissive** (MIT, BSD, Apache 2.0): Maximum freedom, minimal
  obligations.
- **Copyleft** (GPL, AGPL): Requires derivative works to also be
  open-source; viral clause.
- **Weak copyleft** (LGPL, MPL): Middle ground; copyleft applies only to
  modified library files.

## Decision

License the project under the **MIT License**. All dependencies must be
MIT, BSD, or Apache 2.0 compatible. **GPL-licensed dependencies are
prohibited.**

## Consequences

- **Maximum adoption**: Anyone can use, fork, or embed the code in
  commercial products without license friction.
- **Dependency freedom**: The MIT/BSD/Apache constraint keeps the dependency
  tree clean and avoids accidental copyleft contamination.
- **No protection against proprietary forks**: A company could fork the
  project, close the source, and compete. Accepted as a trade-off for
  simplicity and community goodwill.
- **License audit required**: Every new dependency must be checked for
  license compatibility before inclusion.

## Alternatives Considered

- **Apache 2.0**: Similar permissiveness with explicit patent grant; slightly
  more complex. MIT was chosen for simplicity and familiarity.
- **GPL v3**: Would prevent proprietary forks but would also prevent
  inclusion of many Flutter packages and discourage corporate contributors.
- **AGPL**: Even more restrictive; overkill for a client-side mobile app.
