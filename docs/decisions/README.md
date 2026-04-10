# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the
Tankstellen project. ADRs capture important architectural choices alongside
their context and consequences so future contributors can understand *why*
the codebase is shaped the way it is.

## Format

Each ADR follows a consistent template:

| Section                | Purpose                                         |
|------------------------|-------------------------------------------------|
| **Title**              | Short noun phrase: "Use Riverpod for state"     |
| **Status**             | Proposed / Accepted / Deprecated / Superseded   |
| **Date**               | `YYYY-MM-DD` when the decision was accepted     |
| **Context**            | Forces at play, constraints, problem statement   |
| **Decision**           | What we decided and why                         |
| **Consequences**       | Trade-offs, follow-up work, risks               |
| **Alternatives Considered** | Options that were evaluated and rejected   |

## Numbering

ADRs are numbered sequentially (`0001`, `0002`, ...). Numbers are never
reused. If a decision is reversed, the original ADR is marked
**Superseded** with a link to the new one.

## Index

| #    | Title                              | Status   |
|------|------------------------------------|----------|
| 0001 | Use Riverpod over BLoC             | Accepted |
| 0002 | Local-first architecture           | Accepted |
| 0003 | No Firebase or Google Play Services| Accepted |
| 0004 | Hive for local storage             | Accepted |
| 0005 | Service chain fallback pattern     | Accepted |
| 0006 | 23-language i18n strategy          | Accepted |
| 0007 | MIT license choice                 | Accepted |
| 0008 | Storage migration evaluation (v5.x) | Accepted |
