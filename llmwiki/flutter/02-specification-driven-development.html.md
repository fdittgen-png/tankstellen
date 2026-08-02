**02 · Method**

# Specification-driven development

> A specification is not a backlog and not a design document. It is a validated statement of intended behaviour, free of implementation detail, that names its own contradictions and records how each was resolved. Written this way it stays useful for years; written any other way it is stale within a sprint.

**Chunk prefix** spec **Updated** 2026-08-01 **Depends on** —

#### On this page

1. [Why a spec, when you have issues](#why)
1. [Anatomy of a working specification](#anatomy)
1. [Resolving contradictions in writing](#contradictions)
1. [The feature filter](#leitmotiv)
1. [Keeping a spec honest: the amendment discipline](#amendment)
1. [From spec to issues to code](#spec-to-issues)
1. [Epics and the validation gate](#epics)
1. [Specifications and AI assistants](#agents)

<!-- chunk: spec.why | tags: specification,rationale,process -->

## Why a spec, when you have issues

An issue tracker records intent in fragments, ordered by when someone thought of it; a specification records intent as a whole, ordered by how the product works.

The two are not substitutes. In practice, the difference shows up at four moments:

| Moment | With only issues | With a spec |
| --- | --- | --- |
| A new contributor arrives | Reads 300 closed issues to infer the domain model | Reads one document and knows the nouns |
| Two features interact | The interaction is discovered in code review, or in production | The interaction was already a paragraph, because both features are on the same page |
| A requirement is ambiguous | Each implementer resolves it differently; the product acquires two behaviours | The ambiguity is a recorded, resolved contradiction with a rationale |
| An AI assistant is asked to implement something | It infers the domain from the code and confidently invents the parts that are missing | It is pointed at the section that defines the behaviour |

> **[WHY]**

> The most expensive class of defect is not a wrong line of code — it is two subsystems that each behave correctly according to a different reading of the same requirement. That defect cannot be caught by a test, because both sides pass their own tests. It is caught by writing the requirement down once, in one place, and having a human with authority say "yes, that is what I meant".

<!-- chunk: spec.anatomy | tags: specification,template,structure -->

## Anatomy of a working specification

A specification that survives contact with implementation has a specific shape: domain nouns first, behaviour second, everything implementation-flavoured excluded by construction.

| Section | Contains | Explicitly excludes |
| --- | --- | --- |
| **Status header** | Version, validation date, who validated it, repository, licence | — |
| **Vision & leitmotiv** | The two-sentence purpose and the two-to-four goals every feature must serve | Feature lists |
| **Market position** | What exists already and why this is different | Marketing copy |
| **Personas & roles** | Each actor, what they may do, how roles compose | Auth implementation |
| **Domain model** | Every noun, defined once, with its relationships and lifecycle states | Table names, column types |
| **Behaviour, one section per surface** | What happens, in what order, with what edge cases and defaults | Widget names, class names |
| **Rules & configuration** | Every tunable, with its default, as a table | Where the setting is stored |
| **Non-functional constraints** | Privacy, offline behaviour, platform reach, licence constraints | Library choices |
| **Out of scope / later versions** | What was considered and deliberately deferred, with the version | — |

> **[RULE]**

> **No implementation detail in the specification.** No framework names, no package names, no class names, no table names. The test: if switching from one state-management library to another would require editing the spec, the spec is contaminated. Implementation choices belong in architecture decision records, which the spec may link to but must not depend on.

> **[CHECK]**

> Two quick audits that catch most drift. **One:** every noun used anywhere in the behaviour sections appears in the domain model with a definition. **Two:** every configurable value mentioned in prose also appears in the rules table with a default. A tunable named in prose but absent from the table is how two implementers end up choosing two different defaults.

<!-- chunk: spec.contradictions | tags: specification,ambiguity,requirements -->

## Resolving contradictions in writing

Requirements arrive contradictory. The valuable act is not eliminating the contradiction silently but recording it, resolving it, and leaving both the resolution and its reasoning in the document.

The convention that works is a numbered callout inline at the point of resolution:

```markdown
> **Resolved contradiction #1:** the original brief says check-in is "on the
> desk", and elsewhere "to a chair or office". Resolution: the bookable unit
> is the **seat** (the 6×4 slot); the chair is a property of the seat; a whole
> office is bookable only when flagged as such.

> **Resolved contradiction #2:** the brief lists plans as "100%, 50%,
> sometimes, or 50% and then, if more, paying more". Resolution: *"50% and if
> more, pay more"* **is** the Half plan with overage — it is not a fourth
> plan. "Sometimes" is the Flex plan.
```

A second, related convention covers hazards found during research rather than in the brief:

```markdown
> **Resolved pitfall (research):** walk-up versus future-reservation conflicts
> and double-booking races are the #1 failure mode of these systems. All
> availability decisions are transactional and conflict-checked at
> confirmation time, never against a possibly-stale view.
```

> **[WHY]**

> Both callouts do the same job: they stop the question being reopened. Without the written resolution, the third engineer to read the brief re-derives the ambiguity, picks the other reading because it is marginally simpler, and ships a second behaviour. With it, the cost of revisiting the decision is bounded — you can disagree with the recorded reasoning, but you cannot accidentally rediscover the problem.

A resolved contradiction should record three things: *what* was ambiguous, *what* was decided, and — if the decision is not obvious — *why* that reading and not the other. Skip the third only when the resolution is self-evidently the only workable one.

<!-- chunk: spec.leitmotiv | tags: specification,scope,product -->

## The feature filter

Name two to four goals in the specification, and make every feature justify itself against at least one of them. This is the cheapest scope-control mechanism available.

Both source projects use one, and both state it identically in structure — an ordered list of goals, followed by an explicit sentence that a proposal serving none of them is refused before code is written.

| Project | The filter |
| --- | --- |
| `sparkilo` | Every feature must reduce the cost of a kilometre driven: (1) buy fuel for less, (2) burn less of it per kilometre, (3) see what you actually spent. |
| `deskilo` | (1) Know where you can sit, (2) know what you owe or are owed, (3) run the space without a landlord platform. |

The mechanism only works if it is enforced somewhere a proposal cannot avoid. Put the goals in the feature-request issue template as a **required checkbox group**, with the sentence "a feature serving none of these will be pushed back on" next to it. That converts a stated value into a step in the workflow.

> **[RULE]**

> **Order the goals, and treat the order as priority.** An unordered list of goals lets any feature find a justification. An ordered one lets you say "this serves goal three, and we have unfinished work on goal one" — which is the conversation you actually need to have.

<!-- chunk: spec.amendment | tags: specification,maintenance,staleness -->

## Keeping a spec honest: the amendment discipline

A validated specification must not be silently rewritten when the product moves past it. Annotate it instead — an amendment block plus inline superseded-notes — so the original intent and the current reality are both visible.

The problem is structural. The specification's value comes from having been validated by whoever owns the product; rewriting it unilaterally destroys exactly that property. But leaving it unmarked while the product diverges makes it actively misleading. The resolution used successfully:

1. **An amendment block immediately after the preamble**, listing every area where the product has moved past the validated text, each pointing at the decision record or wiki page that now governs.
1. **Inline superseded-notes at the affected sections**, stating what changed and — importantly — whether the *constraint that produced* the original text still holds. A payments section written under a "no third-party SDKs" constraint may be superseded in its specifics while the constraint remains intact; saying so prevents the constraint being discarded along with the paragraph.
1. **An explicit admission where a whole subsystem has no section yet.** "The invoicing chain has no section of its own; see decision record 0010 and the wiki" is honest and actionable. Silence is neither.

> **[TRAP]**

> **Symptom: a design document describes shipped work as a proposal.** One project's payments-integration document opened a section with "new migration (not yet written — ship with the first live provider)" while the document's own status line said "implemented". The migration had shipped months earlier, extended twice. Anyone reading section by section — which is how anyone reads a long document — would have concluded the feature did not exist.

> **Countermeasure:** when a design document's status changes, grep it for future-tense construction ("will", "not yet", "to be", "planned") and resolve every hit. Retitle superseded sections as historical rather than deleting them; the reasoning is often still the best record of why the shipped thing has the shape it does.

> **[RULE]**

> **Maintain a known-gaps section, and put it in the derived overview rather than the spec.** One project's project-overview document ends with a numbered list of every discrepancy between the committed documentation and the verified state of the code, the repository configuration and the live backend — each marked fixed or outstanding. It is the most valuable section in the entire documentation set, because it is the only one that tells you which of the others to distrust. Reproduce this pattern; it costs an hour a quarter and it is the difference between documentation people trust and documentation people route around.

<!-- chunk: spec.spec-to-issues | tags: process,issues,traceability -->

## From spec to issues to code

The chain runs specification → issue → branch → commit → pull request → release note, and every link carries the identifier of the previous one.

> **[RULE]**

> **Never develop without an issue.** Every change traces to one. This is not bureaucracy — it is the mechanism that makes [page 05](05-traceability.html)'s traceability chain possible at all. A commit with no issue is a change whose motivation is unrecoverable in six months.

| Link | Carries | Convention |
| --- | --- | --- |
| Issue → spec | The spec section defining the behaviour | Linked in the issue body; the issue template prompts for it |
| Branch → issue | Type prefix and a slug | `feat/`, `fix/`, `refactor/`, `test/`, `docs/`, `chore/`, `ci/`, `perf/` |
| Commit → issue | Conventional-commit subject naming the scope | `type(scope): imperative subject under 72 chars, no trailing period` |
| PR → issue | Auto-close keyword | `Closes #NN` in the body |
| Release note → PR | Generated from PR titles | Which is why PR titles must be written for a user, not a reviewer |

> **[RULE]**

> **One commit per closed issue, even inside a bundled pull request.** The PR title summarises the bundle; the commit log preserves the per-issue rationale permanently. Squash-merging a five-issue PR into one commit destroys four fifths of that record — so squash each issue's work into its own commit before merging, and merge the PR as a stack of those.

<!-- chunk: spec.epics | tags: process,epics,planning -->

## Epics and the validation gate

Work larger than one pull request, or touching more than one subsystem, becomes an epic — and its breakdown is validated by the maintainer *before* any child issue is filed.

The gate matters more than the format. Filing twelve child issues from an unvalidated breakdown produces twelve issues that all need re-scoping, plus the social cost of closing them. The sequence:

1. **File the epic parent** containing: the goal in user-visible terms with a link to the spec section; a dependency-ordered list of proposed child tasks; risks and open questions; and an explicit validation checkbox.
1. **Stop.** Get the breakdown validated.
1. **Then** file the children, in dependency order, each linking back to the parent.
1. **Close the epic only after every child pull request has merged** — not when they are in flight. A premature close pollutes the open-issue list if any of them is reverted.

| Signal | Task | Epic |
| --- | --- | --- |
| Pull requests needed | One | More than one |
| Subsystems touched | One | Several |
| Needs a decision recorded | No | Usually — often as the first child |
| Schema or migration involved | Rarely | Often |
| Can be described in one sentence | Yes | No |

> **[WHY]**

> Make the *first* child of a design-heavy epic a decision task whose deliverable is an architecture decision record, not code. It costs one issue and it prevents the far more common failure: three implementation children built on three incompatible assumptions, discovered at integration.

> **[TRAP]**

> **Symptom: a parked issue reads as "still open" and nobody knows it is waiting on you.** When work is deferred pending a decision, make the decision-needed state explicit — a label, a comment naming exactly what is being asked, and a proposed default so the answer can be "yes, do that". An issue left open with no marker is indistinguishable from an issue nobody has started, and it will sit there until someone asks why the count is not going down.

<!-- chunk: spec.agents | tags: ai-agents,specification,workflow -->

## Specifications and AI assistants

A written specification is disproportionately valuable when part of the implementation is done by a model, because a model will confidently fill any gap you leave.

Three practices that made the difference:

- **Point at the section, not the repository.** "Implement §5.2 series reservations" produces a scoped change. "Add recurring bookings" produces an invented domain model that will disagree with the one already in the database.
- **Keep a version-controlled rules file that agents load automatically**, and make it a mirror of the binding rules rather than a second source. One project keeps its assistant-facing rules file deliberately untracked for local reasons, and therefore maintains a committed mirror at `docs/AGENT_RULES.md` so a fresh clone on another machine still carries the rules. Whatever the arrangement, the rules must travel with the repository.
- **State the lint rules up front in every implementation prompt.** The rules that cost the most re-work were always the repo-specific ones a model cannot infer: the stack-trace-in-catch requirement, the design-token requirement, the "analyze includes `test/`" requirement. One project recorded the stack-trace rule being violated four times in a single session before it was added to the standard prompt preamble.

> **[CHECK]**

> A specification is agent-ready when a model can answer, from the document alone: what are the nouns, what are the states each noun can be in, what happens on each user action including the error cases, and what is configurable with what default. If it has to read the code to answer any of those, the gap it fills will be an invention.

#### Sources for this page

- One project's owner-validated product specification, including its resolved-contradiction and resolved-pitfall conventions, its ordered feature filter, and its amendment block.
- Both projects' issue templates (bug, feature with the leitmotiv checkbox group, epic with the validation gate), pull-request templates, and committed agent-rules files.
- The known-gaps section of one project's derived overview document, which supplied the staleness examples in [the amendment discipline](#amendment).

The task-versus-epic signal table is a synthesis of both projects' practice rather than a quotation from either.
