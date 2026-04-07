# ADR 0007: MIT license choice

**Status:** Accepted
**Date:** 2024-06-01

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
