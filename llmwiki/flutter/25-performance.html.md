**25 · Quality**

# Performance

> Performance work in Flutter is not one discipline but five: keeping builds cheap, keeping paints cheap, keeping the main isolate free, keeping images small in memory, and keeping the binary small on disk. Each has its own measuring tool and its own failure smell — and the practices here either shipped in one of the source projects or come from the official guidance, labelled accordingly.

**Chunk prefix** perf **Updated** 2026-08-02 **Depends on** 01 Foundations, 03 TDD

#### On this page

1. [Budgets before optimisations](#budgets)
1. [Rebuild discipline](#rebuilds)
1. [Lists, grids and layout passes](#lists)
1. [Custom painters and the repaint contract](#painting)
1. [Impeller, and what it does not fix](#impeller)
1. [The main isolate is for frames](#isolates)
1. [Images and memory](#images)
1. [Startup as a CI budget](#startup)
1. [App size](#size)

<!-- chunk: perf.budgets | tags: performance,budgets,measurement,devtools -->

## Budgets before optimisations

A performance practice starts with numbers, because without a budget every optimisation is a guess and every regression is invisible. These are the budgets that matter and where to read them.

| Budget | Target | Where to measure |
| --- | --- | --- |
| Frame, 60 Hz device | 16 ms total — roughly 8 ms UI thread (build + layout) and 8 ms raster | DevTools → Performance, in **profile mode on a real device** |
| Frame, 120 Hz device | under 8 ms total | same |
| Cold start to first frame | a committed number per app — then a CI job that fails when it grows | a startup-budget CI check (below), `adb shell am start -W` |
| Main-isolate work item | a few milliseconds; beyond that it belongs on an isolate | DevTools CPU profiler |
| Release artifact size | a tracked number, not a feeling | `--analyze-size` + the DevTools App Size tool |

> **[RULE]**

> **Measure in profile mode on a real device, never in debug on a simulator.** Debug builds run with assertions, without AOT, and with a different rasteriser path; a simulator has desktop-class CPU and no thermal envelope. Every number collected outside profile-mode-on-device is noise, and optimising against noise makes code worse for nothing.

> **[CHECK]**

> Press `P` in the run terminal (or enable the performance overlay) and scroll the busiest screen on the slowest device you support. Red bars in either graph are dropped frames. If the overlay is calm there, the app is fine — stop optimising and go build features.

<!-- chunk: perf.rebuilds | tags: performance,build,rebuilds,const,riverpod -->

## Rebuild discipline

The cheapest frame is the one that rebuilds almost nothing, and rebuild scope is decided by code structure, not by the framework. Four habits keep it narrow.

| Habit | Mechanism |
| --- | --- |
| **`const` everywhere the analyzer allows** | A `const` widget is reused, not rebuilt. Both projects enforce `prefer_const_constructors` as an analyzer lint, which turns the habit into a build error rather than a review comment. |
| **Split big `build()`s into widget classes** | A widget class is a rebuild boundary; a helper function returning a widget is not. Extracting a subtree into its own `StatelessWidget` localises both rebuild scope and `const`-ability. The file-length budget from [page 01](01-foundations-architecture.html#boundaries) pushes in the same direction for a second reason. |
| **Watch narrow state** | With Riverpod, a widget that watches a whole async provider rebuilds on every change; watching a `select`-ed field, or splitting derived providers (the [derived-provider graph](01-foundations-architecture.html#state)), rebuilds only what changed. The provider graph is the rebuild graph. |
| **Pass `child` into animated builders** | Subtrees that do not depend on the animation are built once and handed to `AnimatedBuilder`/`ListenableBuilder` as `child`, not rebuilt per tick inside the builder closure. |

> **[TRAP]**

> **Symptom: a screen rebuilds on every provider change although nothing visible depends on it.** The usual cause is a broad `ref.watch` in the screen's own `build` for a value only one small widget needs. Move the watch down into the widget that uses it. The one-line diagnostic is the IDE's "show widget rebuild information" toggle — widgets flashing on unrelated changes are watching too much.

One rule from the official guidance is worth repeating because it is invisible until it hurts: **never override `operator ==` on a widget class** to "help" the framework skip rebuilds. It turns tree diffing quadratic and usually pessimises the exact path it meant to optimise.

<!-- chunk: perf.lists | tags: performance,lists,layout,slivers -->

## Lists, grids and layout passes

List performance is decided by two questions: are off-screen children built, and does layout need to interrogate children to size them. The answer to both should be no.

- **Builder constructors for anything unbounded.** `ListView(children: [...])` builds every child; `ListView.builder` builds what is visible. The same for `GridView.builder`. A concrete-list constructor is fine only when the list is short and mostly on-screen.
- **Fixed extents beat measured extents.** `itemExtent` or `prototypeItem` lets the scroll machinery jump to any offset arithmetically instead of laying out everything in between. One source project pins its timeline row heights, header heights and hour widths as named constants in a single geometry class — which serves layout speed *and* gives tests a stable coordinate contract to assert against.
- **Avoid intrinsic passes.** `IntrinsicHeight`/`IntrinsicWidth` and tables without fixed column widths make layout O(N²)-ish by measuring children twice. DevTools' *Track layouts* option surfaces them as `'$runtimeType intrinsics'` events.
- **Fold data once per frame, not once per cell.** A grid of N cells that each scan a list of M records does N×M work per build. One source project's month-availability grid hit exactly this and was refactored — after a profiled audit, not a hunch — to one fold over the reservations that produces a per-day map the cells index into. The pattern generalises: derive per-item view state in one pass above the list, hand each cell a lookup.

> **[WHY]**

> Deriving view state above the list rather than in each cell also moves the logic into a pure function that a unit test can cover without pumping a widget — the performance fix and the testability fix are the same refactor. This is the recurring shape of good Flutter performance work: the fast structure and the testable structure coincide.

<!-- chunk: perf.painting | tags: performance,custompainter,repaint,opacity,cliprect -->

## Custom painters and the repaint contract

A canvas-heavy surface — a floor plan, a chart, a map overlay — lives or dies by its `shouldRepaint`, because the framework repaints whenever the painter instance changes unless told otherwise.

> **[RULE]**

> **`shouldRepaint` compares every field that affects output, and nothing else.** Comparing too little produces stale pixels; comparing too much (or defaulting to `true`) repaints the world on every build. Collections need value comparison — one source project's floor-plan painter compares its seat-id sets with `setEquals`, because reference equality on a freshly-built set would report a change every frame. Treat the field list in `shouldRepaint` as part of the painter's API: every new painter field must appear there, and a code review that adds a field without touching `shouldRepaint` has found a bug.

Around the painter, three framework-level costs dominate, all from the official guidance and all confirmed in practice:

- **`saveLayer()` is the expensive call.** It allocates an offscreen buffer and switches render targets — costly on mobile GPUs. Widgets can trigger it without you writing it: `Opacity` over a subtree, `ShaderMask`, `ColorFilter`, certain `Chip` and `Text` configurations. DevTools' checkerboard options show where offscreen layers happen.
- **Opacity has cheaper spellings.** Fading an image? `FadeInImage` or opacity on the image paint itself. Animating a fade? `AnimatedOpacity`. A semi-transparent rectangle? A semi-transparent *color*, no wrapper widget at all.
- **Clip less, and never `Clip.antiAliasWithSaveLayer` casually.** Rounded corners via `borderRadius` on a decoration are cheaper than `ClipRRect` around a subtree; pre-clip static images once instead of clipping every frame of an animation.

For pan-and-zoom canvases, transform instead of repainting: an `InteractiveViewer` applying a matrix to an already-painted layer is cheap; recomputing the painting at every gesture tick is not. A `RepaintBoundary` around the canvas isolates it from surrounding UI churn — but add boundaries from profiler evidence, not speculatively, because each one costs memory for its layer.

<!-- chunk: perf.impeller | tags: performance,impeller,shaders,jank -->

## Impeller, and what it does not fix

Impeller — the default renderer on iOS and on modern Android — removes the classic first-run stutter by compiling shaders ahead of time instead of on first use. What used to be a whole discipline (shader warm-up captures, SkSL bundling) is gone on Impeller targets, and a page of advice with it.

What Impeller does *not* change: everything else on this page. Overdraw, `saveLayer` pressure, oversized images and main-isolate stalls jank exactly as before — Impeller moves work off the first encounter, it does not make work free. Two practical notes:

- **Old Android devices may still run Skia.** If your user base skews old (one source project's does, by domain), test the slowest supported device and do not assume the Impeller baseline. The renderer in use is printed at startup in verbose logs.
- **Renderer bugs are version-coupled.** When a visual artifact appears only on one platform after a Flutter upgrade, check the engine tracker for the renderer before debugging your own paint code — and record the finding next to the pinned Flutter version ([page 01](01-foundations-architecture.html)) so the next upgrade re-checks it.

<!-- chunk: perf.isolates | tags: performance,isolates,compute,async -->

## The main isolate is for frames

Dart's `async` does not create parallelism — an `await`ed JSON parse of a large payload still blocks frame production, because it runs on the main isolate between frames. The budget from the first section applies: a few milliseconds of synchronous work is fine; beyond that, move it.

| Work | Where it belongs |
| --- | --- |
| Parsing a large API response (rule of thumb: hundreds of KB and up) | `Isolate.run()` / `compute()` |
| Building a PDF, an XLSX, an export archive | Off the frame path — an isolate, or at minimum chunked awaits; and behind a progress affordance, never a frozen tap |
| Image decode at display size | The engine's decode thread — reached by giving it a target size (next section) |
| Database/preferences reads at startup | After first frame (see [startup](#startup)) |

> **[TRAP]**

> **Symptom: a widget test that exercises a heavy export hangs for ten minutes and then times out.** Real async work — font asset loading, image encoding — cannot complete inside `FakeAsync`-pumped test time. The fix is `tester.runAsync()` around the triggering tap, which both projects' export tests do. The trap recurs every time a new export path gains its first test, which is why it is recorded here and in the test helpers.

Isolate boundaries copy their arguments (or transfer, for `TransferableTypedData`), so hand an isolate the raw bytes and get structured results back — do not ship it a lambda closing over half the app state, which serialises poorly and couples the isolate to everything the closure touches.

<!-- chunk: perf.images | tags: performance,images,memory,cache -->

## Images and memory

Decoded images are the single largest memory consumer in a typical app, and the failure is silent: a 4000×3000 photo displayed in a 100 dp avatar still decodes at 48 MB unless something says otherwise.

- **Decode at display size.** `Image.memory(..., cacheWidth: ...)` / `cacheHeight`, or `ResizeImage`, makes the engine decode to the target resolution. For network images behind a list, a disk-and-memory caching loader keeps scroll-back from re-fetching and re-decoding.
- **Know the `imageCache` limits.** The global cache defaults to 1000 entries / ~100 MB; a gallery-like surface can either blow past it (evictions, re-decode jank) or hold far too much (memory pressure, background kill). Both directions are tunable — but only after DevTools' Memory view shows which direction you are failing in.
- **Dispose what you own.** Controllers, streams, listeners, `ui.Image` handles from custom decode paths. One source project decodes floor-plan background photos to `ui.Image` for its painter — a path where a forgotten dispose leaks the full decoded bitmap, not a few bytes of Dart object.
- **Precache what the next screen definitely shows** (`precacheImage`) — and nothing else. Speculative precaching is how memory problems start.

> **[CHECK]**

> DevTools → Memory, on device, in profile mode: scroll every image-bearing surface, background the app, resume. A saw-tooth that returns to baseline is healthy; a staircase is a leak; an OS kill in the background is the image cache holding too much. On Android, an unexplained background kill also shows up in `ApplicationExitInfo` — the same forensics channel [page 27](27-recurring-bugs.html#notraces) uses for crashes.

<!-- chunk: perf.startup | tags: performance,startup,ci,budget -->

## Startup as a CI budget

Cold start decays by accretion — every feature adds "just one" initialisation — so the only durable defence is a number that CI enforces. One source project runs a dedicated startup-budget job among its required checks; the other proves its release artifact boots at all ([the aliveness test](13-android.html#r8)). Both are versions of the same idea: **the artifact's runtime behaviour is a CI assertion, not a hope**.

The ordering rule that keeps the number small: *first frame first*. Everything that is not needed to paint the boot screen moves after it —

- Database / preferences opens, cache eviction sweeps, notification channel setup: after first frame, in an initializer that runs behind the splash.
- Network refreshes: after first frame, rendering from cache meanwhile ([page 06](06-caching.html)'s stale-tier exists precisely so startup never waits on a network).
- Heavy, rarely-used capability code (an OCR model, a map stack) on Android: a deferred component downloaded on demand, which also moves its bytes out of the initial download.

> **[RULE]**

> **Lazy providers are the startup graph.** With Riverpod, nothing runs until first watched — so keeping construction side-effect-free and initialisation explicit (an app-initializer seam, not constructor work in a `keepAlive` provider) means the boot path is exactly the providers the boot screen watches, and adding a feature cannot slow the start by existing. Constructor side effects in eagerly-created singletons are how startup budgets die.

<!-- chunk: perf.size | tags: performance,app-size,analyze-size,obfuscation -->

## App size

Size is measured on release artifacts and tracked over time; a debug build's size means nothing. The toolchain gives exact numbers.

| Technique | Command / mechanism |
| --- | --- |
| Measure with attribution | `flutter build apk --analyze-size` (any target) → open the JSON in DevTools' App Size tool for a per-package treemap |
| True store size | Play Console's download/install sizes for an AAB; the App Thinning Size Report from an Xcode archive — stores strip per-device, so the local file overstates |
| Strip symbols, keep crash mapping | `--split-debug-info=<dir>` (+ `--obfuscate`) — both source projects ship this on iOS and archive the symbols as CI artifacts, because a stripped build without archived symbols makes every crash report unreadable ([page 05](05-traceability.html)) |
| Per-ABI delivery | An AAB does it server-side on Play; `--split-per-abi` for sideload APKs — one project ships per-ABI splits on its libre channel |
| Dead weight | Icon tree-shaking is on by default; compress bundled PNG/JPEG; audit `assets/` for files nothing references; platform-conditional code behind `Platform.isX` checks compiles out of other targets |

> **[TRAP]**

> **Symptom: the app grew 30 MB and nobody can say when.** Size has no equivalent of a failing test unless you build one — sizes drift in dependency bumps and asset additions that each look innocent. The cheap fix is a CI step that prints the release artifact size into the job summary on every build (both projects' packaging workflows do, one of them failing outright when the artifact is implausibly small — the [empty-harvest trap](16-windows.html#harvest) in reverse). The number being visible in every PR is usually enough; a hard budget is the escalation if it is not.

#### Sources for this page

- The official Flutter performance best-practices and app-size pages (build costs, `saveLayer`, opacity/clipping, intrinsic passes, `operator ==`, `--analyze-size`, deferred components), cross-checked 2026-08.
- One project's profiled month-grid fold ("one occupancy fold for the whole grid instead of one reservation scan per cell"), its painter's `setEquals`-based `shouldRepaint`, its pinned timeline geometry constants, its `tester.runAsync` export-test pattern, and its post-first-frame boot initializer.
- The other project's startup-budget required check, per-ABI splits, and both projects' `--split-debug-info` + symbol-archiving release lanes.
- Impeller status (default on iOS and modern Android; AOT shader compilation) from current official and ecosystem write-ups, 2026-08.

The image-cache tuning numbers and the RepaintBoundary advice are general guidance rather than observed practice in the source projects; treat thresholds as starting points to be profiled, not facts.
