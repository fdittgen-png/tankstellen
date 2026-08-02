**00 · Start here**

# How to use this wiki

> This page is the contract between the wiki and its readers — both the human kind and the retrieval pipeline kind. It defines what a page is made of, what each callout means, how to tell where a claim came from, and how to slice these documents for a context window without destroying their meaning.

**Chunk prefix** howto **Updated** 2026-08-01 **Depends on** nothing

#### On this page

1. [The document model](#model)
1. [Callout taxonomy](#callouts)
1. [Provenance and staleness](#provenance)
1. [The chunking contract](#chunking)
1. [Getting Markdown out of these pages](#markdown)
1. [If you are an agent](#agents)

<!-- chunk: howto.model | tags: structure,conventions -->

## The document model

Every content page in this wiki has the same shape, and the shape is load-bearing.

| Element | Purpose | Machine handle |
| --- | --- | --- |
| Kicker + `h1` | Page number, group, title | `<h1>`, JSON-LD `headline` |
| Lede paragraph | One-paragraph answer to "what is this page for" | `.lede`, JSON-LD `description` |
| Meta strip | Chunk prefix, last update, prerequisite pages | `.meta` |
| Table of contents | Human navigation within the page | `.toc` |
| `section` blocks | One self-contained idea each, opening with a claim sentence | `data-chunk-id`, `data-tags`, `id` |
| Callouts | Rules, traps, rationale, verification | `.callout.rule` / `.trap` / `.why` / `.check` |
| Source box | Where the page's claims came from and what is inference | `.sourcebox` |

Three properties matter more than the rest:

- **Each `<section>` is self-contained.** It opens with a sentence that states its claim outright, so the section still makes sense when it is lifted out of the page and shown alone. No section begins with "this", "the above", or "as we saw".
- **Facts live in tables, not in prose.** A version number, a threshold, a permission name or a track name goes in a table cell. Prose is for reasoning; tables are for lookup.
- **Navigation is injected at runtime, not duplicated in the HTML.** The sidebar is built by `assets/wiki.js` from a single array. A text extractor that ignores scripts therefore gets the page's content and none of the twenty-two-item navigation list repeated on every page. Boilerplate repetition is the largest single source of noise when documentation is chunked, so removing it from the static markup is deliberate.

> **[WHY]**

> Retrieval systems chunk on structure. When a page is a wall of prose with implicit references, the chunker either produces fragments that cannot be understood alone, or it has to over-fetch neighbouring text to compensate. Writing each section as a standalone unit with an explicit claim sentence and an explicit heading path costs the author a little redundancy and saves the reader — machine or human — from having to reconstruct context.

<!-- chunk: howto.callouts | tags: conventions,callouts -->

## Callout taxonomy

There are exactly four callout types, and each carries a different obligation on the reader.

> **[RULE]**

> **A binding constraint.** Violating it is a defect, not a style preference. Rules are the ones worth machine-enforcing — and where a project has done so, the rule names the test that enforces it. If a rule seems wrong for your project, change it deliberately and record why; do not simply ignore it.

> **[TRAP]**

> **A failure that actually happened.** Every trap states the symptom first, because the symptom is how you will recognise it at 2am, and only then the cause and the fix. If a trap has bitten more than once, it says how many times — recurrence count is the best available signal for how easy something is to get wrong.

> **[WHY]**

> **The rationale behind a decision.** Recorded so it can be re-litigated on evidence rather than on taste. A rule whose rationale has been lost gets deleted by the next person who finds it inconvenient — which is the actual mechanism by which hard-won engineering knowledge evaporates from a codebase.

> **[CHECK]**

> **The verification step.** The command, test or observation that proves the thing works. A page that tells you to do something without telling you how to confirm it worked has not finished the job.

<!-- chunk: howto.provenance | tags: conventions,provenance,trust -->

## Provenance and staleness

Claims in this wiki are labelled by origin, because a practice proven in one domain may not transfer to another.

`sparkilo` Observed in the fuel/EV price-comparison app: 17 country APIs, 23 locales, OBD-II over Bluetooth, a sharded CI, a libre F-Droid build accepted against a dex-level audit.

`deskilo` Observed in the coworking booking and ledger app: Supabase with 73 immutable migrations, OAuth without a vendor SDK, NFC/RFID kiosk, macOS/Windows/web targets, an owner-validated product specification.

`both` Practised in both, usually because one inherited it from the other and it survived contact with a second domain. These are the highest-confidence recommendations in the wiki.

> **[RULE]**

> **Record discrepancies; do not silently reconcile them.** When the documentation and the code disagree, the honest move is to write down the disagreement — with a marker for whether it has been fixed — rather than quietly editing one to match the other. One of the source projects keeps a dedicated *Known gaps and stale documentation* section for exactly this, listing each divergence between the committed docs and the verified state of the code, the repository configuration and the live backend. That section is the single most valuable page in its documentation set, because it is the only one that tells you which of the others to distrust.

> **[TRAP]**

> **Symptom: a documented invariant that nothing enforces.** One project's wiki stated that direct pushes to `master` were blocked, that PRs needed green CI, and that only squash-merges were allowed. The GitHub API reported no branch protection and no rulesets at all — the rules were honoured by convention alone, and nothing on the server would have stopped a red merge. Documentation that describes a guarantee the infrastructure does not provide is worse than no documentation, because it stops people from checking.

> **Countermeasure:** for every invariant your docs assert, name the mechanism that enforces it in the same sentence. If you cannot name one, write "by convention only" — and then decide whether that is acceptable.

Every page ends with a source box stating what was read to produce it and flagging which claims are recommendations rather than observations. Pages carry a `dateModified` in their JSON-LD. Treat anything with a version number, a threshold or a URL as potentially stale and verify against the repository before acting on it.

<!-- chunk: howto.chunking | tags: retrieval,rag,chunking -->

## The chunking contract

These pages are built to survive being cut into retrieval chunks, and the markup tells you where to cut.

| Attribute | On | Meaning |
| --- | --- | --- |
| `data-chunk-id` | `<section>` | Stable global identifier, `<page-prefix>.<slug>`. Safe to use as a primary key; it does not change when a page is reordered. |
| `data-tags` | `<section>` | Comma-separated topic tags for metadata filtering. |
| `id` | `<section>` | URL fragment for citation: `13-android.html#r8`. |
| `data-lang` | `<pre>` | Language of the code block, rendered as a label and available to a syntax pass. |

Recommended pipeline, following the current mainstream guidance for documentation retrieval:

1. **Chunk on `<section>` boundaries first.** Sections are authored at roughly 300–900 words, which lands inside the 400–1500 token window that fixed-size chunking targets — without the arbitrary cut points.
1. **Prepend the heading path to every chunk** before embedding: `LLM Wiki · Flutter › 13 Android › R8 and the class it silently strips`. This is contextual retrieval, and it is the cheapest single improvement available: it makes a chunk self-describing without changing the source.
1. **Split oversized sections at `<h3>`,** repeating the parent `h2` in the heading path. Never split inside a `<table>`, a `<pre>` or a `.callout` — those are atomic units and half of one is misinformation.
1. **Store `data-chunk-id`, the source file, the heading path and `dateModified` alongside the vector.** You need all four for citation, for freshness filtering, and for invalidating a chunk when its page changes.
1. **Keep the callout class in the metadata.** Being able to filter for "all rules" or "all traps" across the wiki turns it into a checklist generator, which is a genuinely different use than prose search.

> **[CHECK]**

> A chunk is correctly formed if it answers, on its own, the question "what does this tell me to do, and why". If reading it alone leaves you needing the previous section, the chunk boundary is wrong or the section was written badly — either way, fix the source rather than widening the window.

<!-- chunk: howto.markdown | tags: tooling,markdown,llms-txt -->

## Getting Markdown out of these pages

The [llms.txt](https://llmstxt.org/) convention asks that each HTML page also be available as clean Markdown at the same URL with `.md` appended. This wiki ships a generator rather than hand-maintained twins, because two copies of the same prose diverge.

```bash
python3 tools/build_md.py          # writes <page>.html.md next to each page
python3 tools/build_md.py --full   # also writes llms-full.txt (everything concatenated)
```

The generator is standard-library-only, walks the same semantic structure described above, drops the navigation and scripts, and preserves tables, code blocks and callouts (as blockquotes prefixed with the callout type). Its output is what you should feed to a retrieval pipeline; the HTML is for humans.

> **[WHY]**

> Markdown twins could have been written by hand, and for a five-page site that is fine. At twenty-two pages, hand-maintained duplicates guarantee that within a month the HTML and the Markdown will disagree, and nobody will know which is current. A generator has exactly one source of truth and fails loudly when the structure it expects is missing.

<!-- chunk: howto.agents | tags: agents,workflow -->

## If you are an agent

Read `llms.txt` first, fetch only the pages it names for your task, and do not fetch the whole wiki speculatively.

- **The `## Optional` section of `llms.txt` is genuinely optional.** Page 21 is a comparative audit of the two source projects; it is useful for deciding between conflicting practices and useless for implementing anything. Skip it under context pressure.
- **Cite by chunk id or by URL fragment,** not by page number alone. Page numbers are stable but sections move.
- **When this wiki and the repository disagree, the repository wins.** This is derived documentation. Verify any version, threshold, filename or workflow name against the tree before you act on it — several are pinned deliberately and several are stale by design pending an upstream change.
- **Do not treat a rule as advisory because it is inconvenient.** Where a rule names an enforcing test, that test will fail your pull request; where it does not, it probably should, and adding it is a legitimate contribution.

#### Sources for this page

- The [llms.txt specification](https://llmstxt.org/) — file location, H1 + blockquote + `##` link-list structure, the meaning of the `Optional` section, and the `.md` companion recommendation.
- Current documentation-retrieval practice: section-boundary chunking, heading-path prepending (contextual retrieval), and storing section/source/timestamp metadata alongside the vector.
- The two source repositories' own documentation conventions, in particular the *Known gaps and stale documentation* pattern and the provenance-labelling habit.

The callout taxonomy and the chunk-attribute scheme are this wiki's own conventions, not an external standard.
