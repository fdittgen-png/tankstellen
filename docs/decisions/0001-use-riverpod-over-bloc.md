# ADR 0001: Use Riverpod over BLoC

**Status:** Accepted
**Date:** 2024-06-01

## Context

The app needed a state management solution that supports code generation,
scales to 50+ providers, and integrates naturally with Flutter's widget tree.
The two leading candidates in the Flutter ecosystem were BLoC and Riverpod.

BLoC is well-established and enforces a strict event/state pattern, but
requires significant boilerplate (events, states, blocs) for each feature.
Riverpod offers a more concise API with compile-time safety, code generation
via `riverpod_generator`, and fine-grained reactivity without `BuildContext`.

## Decision

Use **Riverpod 2.x** (later upgraded to 3.x) with `@riverpod` code
generation for all application state. Providers are the single source of
truth; widgets use `ref.watch()` for reactive rebuilds and `ref.read()` for
one-shot actions.

## Consequences

- **Reduced boilerplate**: No event classes or state classes needed; a single
  annotated function or class replaces an entire BLoC.
- **Compile-time safety**: The generator catches provider dependency errors
  at build time rather than runtime.
- **Learning curve**: Contributors must understand Riverpod's `ref` model and
  the difference between `keepAlive` and auto-dispose providers.
- **Generated code in git**: `.g.dart` files are committed to avoid requiring
  `build_runner` for every checkout.

## Alternatives Considered

- **BLoC**: Too much ceremony for a solo-developer project; event/state
  explosion across 11 country APIs.
- **Provider (package)**: Predecessor to Riverpod with known limitations
  around `BuildContext` dependency and lack of code generation.
- **GetX**: Insufficient type safety and unconventional patterns that would
  hinder future contributors.
