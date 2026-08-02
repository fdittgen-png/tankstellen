**24 · Appendix**

# Two projects compared

> This wiki merges two codebases that share a methodology and diverge in practice. Where they diverge, one of them is usually right — and it is not always the older or larger one. This page is the audit: what each does better, what each is missing, and which to copy.

**Chunk prefix** cmp **Updated** 2026-08-01 **Status** Optional — useful for deciding between practices, not for implementing

#### On this page

1. [The two projects](#profiles)
1. [What the younger project does better](#deskilo-better)
1. [What the older project does better](#sparkilo-better)
1. [What both are missing](#gaps)
1. [Verdicts where they disagree](#verdicts)
1. [If you adopt only five things](#adopt)

<!-- chunk: cmp.profiles | tags: comparison,context -->

## The two projects

|   | `sparkilo` | `deskilo` |
| --- | --- | --- |
| Domain | Fuel and EV price comparison, 17 countries, OBD-II trip recording | Coworking desk booking plus a community money ledger |
| Age | ~2 years | ~1 month at the time of this audit |
| Dart files | Large — hundreds of features across 29 feature modules | 293 |
| Tests | ~1 500 files, ~15 000 cases | 161 files, 1 013 cases |
| Locales | 23 + a pseudo-locale | 5 |
| Backend | Optional sync; 17 third-party data sources | Supabase-first; 73 migrations, 5 edge functions |
| Platforms | Android, iOS, Android Auto | Android, iOS, **macOS, Windows, web** |
| Channels | Play, App Store, self-hosted libre repo, catalog submission | Play, TestFlight, libre recipe (draft), DMG, MSI, Pages |
| CI workflows | 20 | 10 |
| Distinctive strength | Depth of enforcement and CI engineering | Honesty of documentation and breadth of platforms |

The second inherited the first's conventions nearly wholesale, which makes the divergences informative: each one is a place where a second domain, or a second look, produced a different answer.

<!-- chunk: cmp.deskilo-better | tags: comparison,documentation,practices -->

## What the younger project does better

Twelve practices worth importing wholesale. Several are documentation habits, which is not a coincidence — a young project writes its documentation while it still remembers why.

### 1. A known-gaps section that names its own stale documentation

> **[RULE]**

> Its overview document ends with a numbered list of every discrepancy between the committed documentation and the verified state of the code, the repository configuration and the live backend — each marked fixed or outstanding, each with the evidence. It records that its own branch protection does not exist despite three documents claiming it does; that two tests are date-dependent time bombs; that its coverage gate is not a meaningful ratchet; that a design document described shipped work as a proposal.

> This is the most valuable section in either project's documentation, because it is the only one that tells you which of the others to distrust. The older project has no equivalent — its overview is uniformly confident, which means a reader cannot tell where it is stale.

### 2. "Derived document" framing

Its overview opens by saying what it consolidates and that the originals remain authoritative for their own areas, with discrepancies recorded rather than silently reconciled. That single paragraph sets the right expectation and licenses the known-gaps section that follows.

### 3. Quantified scale

A table of measured counts — source files, test cases, migrations, translation keys, routes, workflows — near the top. It makes staleness detectable: when the README said "30 migrations" and the tree had 73, the table is what surfaced it.

### 4. An owner-validated, implementation-free specification

A real product specification with a validation date and a named validator, deliberately free of framework and class names, carrying numbered *resolved contradictions* and *resolved pitfalls*. The older project has decision records and an excellent README, but no equivalent statement of intended behaviour — its behaviour is defined by its code and its issue history. See [page 02](02-specification-driven-development.html).

### 5. Every CI mechanic annotated with the failure that produced it

Its CI documentation reads as a series of earned lessons: the keychain that hangs a job in silence, the CocoaPods installation broken by a Ruby switch, the token that kept returning 403, the harvest path that silently produced empty installers, the shrinker that stripped a reflective dependency. Each is stated as symptom → cause → fix. The older project has more sophisticated CI and documents mostly the *what*.

### 6. "Degrades honestly" as a named principle

An unsigned artifact is named `-unsigned` and carries a warning explaining what the user must do, because *a file the OS refuses to open is worse than one that admits what it is*. The principle generalises to fallback data, partial exports and skipped uploads — and it is the frame under which [page 04](04-robustness.html#honest) is written.

### 7. An irreplaceable-material list

An explicit inventory of secrets that cannot be regenerated — the once-downloadable API key, the passphrase whose loss makes an encrypted repository useless, the master keystore — with backup locations. Written after losing one of them.

### 8. Separating what automation cannot do

A per-channel list of owner-only steps with no API: create the app record, grant the service account permission, enable a portal-only capability, fill the console-only forms. This is what makes a launch plan realistic rather than optimistic.

### 9. A release-launch aliveness test on a real emulator

> **[RULE]**

> A workflow that builds the shrunk release artifact, installs it on an emulator, launches it with a deterministic activity name, waits fifteen seconds and asserts the process still exists — with a cached emulator snapshot cutting the job to about two minutes. It was written after release builds crashed before the first frame because the shrinker stripped a reflective dependency, and it catches that entire class. The older project, with vastly more tests, has nothing that proves its release artifact runs. See [page 13](13-android.html#r8).

### 10. A permission matrix kept in lockstep

A document mapping every table and operation to every role with the enforcing mechanism, plus a rule that any migration touching a table, policy or privileged function updates the matrix in the same pull request, re-runs the security advisors, and pastes the advisor output into the pull-request description. Four parts, all required.

### 11. Documentation as a build input

Its wiki user guides are compiled into in-app offline help by a build tool. Documentation that is also a shipped artifact does not rot quietly, because a rendering failure is a build failure.

### 12. Small engineering conveniences worth stealing

- **A guarded-mutation helper** replacing the ten-line try/catch every call site was open-coding, with a boolean return so failure cannot fall through into the success path ([page 04](04-robustness.html#guarded)).
- **A three-state hardware availability enum** — ready, off, unsupported — written after a field report that a tap "was not read" with no way to distinguish three causes ([page 12](12-nfc-rfid.html#status)).
- **The bare-`flutter test` warning**: piping the command yields the pipe's exit code, so a red run reads as green.
- **The migration-drift lesson written back into the docs**: a migration row with no matching file is not evidence of drift until you have read the file. The correction of an earlier wrong conclusion is recorded rather than quietly edited.

<!-- chunk: cmp.sparkilo-better | tags: comparison,ci,enforcement -->

## What the older project does better

Mostly enforcement and CI engineering — the things a codebase acquires when many people, human and otherwise, have had the chance to violate a convention.

### 1. Branch protection codified as data

A script holding the required-check list as an array, with a verify mode that diffs the live configuration and an idempotent apply mode. The younger project documents branch protection in three places and has none — the API reports no protection and no rulesets. The rules are honoured by convention alone. This is the sharpest contrast between the two.

### 2. Twenty-six repo-specific static lint tests

Plain Dart tests that read the source tree and enforce layering, error handling, localisation, design tokens, platform abstraction, routing, contracts and documentation parity — each with a ratcheting baseline that may only decrease. The younger project relies on the analyzer plus review. Over two years, the difference compounds.

### 3. CI that scales

Four-way test sharding, a green-tree cache that skips heavy jobs when the identical source tree already passed, per-step gating for matrix jobs, change-scoped audit jobs, and a stub workflow that re-emits every required context for documentation-only changes. The younger project runs a single sequential job — correct for its size, with no path to a fifteen-thousand-test suite.

### 4. A fifth hard rule for backend parity

Client/server schema parity is a numbered hard rule with a drift-guard test that fails when a synced table is missing from the setup SQL. The younger project has the practice in its conventions but not as a rule with a test.

### 5. A pseudo-locale for text expansion

A generated locale that expands every string, catching layout overflow before a translator does. Cheap, and it catches a class of bug that only appears in languages the developer does not read.

### 6. Depth in the areas it has lived in

- **The service-chain abstraction** — fresh/stale/miss with provenance in the result type, over 17 unreliable third-party sources. The younger project ported the cache but not the chain.
- **A three-layer libre audit** reaching the bytecode-reference bar a catalog scanner actually applies. The younger project greps its dependency declarations — which would not have caught the rejection the older one received.
- **An endpoint canary** that live-probes every third-party source weekly and tracks outages in one rolling issue.
- **Fifteen decision records**, one superseded with a forward link, and a test enforcing their format.
- **Crash forensics** — process-death record harvesting, crash-surviving breadcrumbs, and episode gating so one outage cannot evict the traces you need.

### 7. Parallel-agent orchestration doctrine

A written file-affinity discipline for running many concurrent implementation agents: file-disjoint work goes to separate agents, same-file work to one, named conflict-magnet surfaces are serialised, and a thirty-second ownership check precedes every wave. Specialised, and the only written treatment of the problem in either project.

<!-- chunk: cmp.gaps | tags: comparison,gaps -->

## What both are missing

| Gap | Detail |
| --- | --- |
| **A meaningful coverage ratchet** | Both gate at 45%, which a thousand-test suite clears without effort. The younger project says so in its own known-gaps section. A gate that has never failed a build is not a control. |
| **Pinned clocks in tests** | Two date-dependent tests in one project went red at a month boundary with no commit in between. Neither project injects a clock by default in its shared test overrides. |
| **Cross-pollination of platform knowledge** | One has the Bluetooth depth and no desktop; the other has desktop, NFC and barcode and no Bluetooth. Neither documents the other's area — which is one of the reasons this wiki exists. |
| **Tester management at scale** | Neither uses a Google Group for closed-track testers; both maintain lists by hand. See [page 20](20-testers-google-groups.html). |
| **End-to-end verification of external integrations** | One project's e-invoice path is built, logged and untested against a real endpoint — which it states honestly. The general lesson: an adapter with unit tests proves nothing about the external system's acceptance. |
| **Automated regeneration of the secondary lockfile** | The libre lockfile is regenerated by hand on every dependency bump, going red in between. Trivially scriptable, done in neither. |
| **Licence-header completeness** | One project relicensed and left ten files declaring the old licence. A header check is twenty lines. |

<!-- chunk: cmp.verdicts | tags: comparison,decisions,recommendations -->

## Verdicts where they disagree

| Question | Older | Younger | Verdict |
| --- | --- | --- | --- |
| Branch protection | Codified, verified, enforced | Documented, absent | **Older.** Either enforce it or write "by convention only" — the current state is the worst of both. |
| Known-gaps section | None | Detailed, marked, dated | **Younger.** Highest-value single practice in this comparison. |
| Product specification | Code plus decision records | Owner-validated, implementation-free | **Younger** — provided the amendment discipline is maintained. An unmaintained spec is worse than none. |
| Enforcement style | 26 machine-checked rules | Analyzer plus review | **Older.** Conventions decay; tests do not. |
| CI architecture | Sharded, cached, gated | Single sequential job | **Younger for its size, older as the destination.** Do not shard 1 000 tests; do plan for it. |
| Release-artifact verification | Builds it | Builds it *and boots it* | **Younger.** Compilation is not evidence of launching. |
| Libre audit depth | Three layers to the bytecode-reference bar | A dependency-declaration grep | **Older.** The weaker bar would not have caught the real rejection. |
| Error-handling ergonomics | Rules plus lint tests | A helper that makes the correct path shortest | **Both.** The helper reduces violations; the lint catches the rest. |
| Platform breadth | Mobile plus car | Mobile plus three desktop targets | **Younger**, if you want them. Each target is a permanent maintenance commitment. |
| Locale strategy | 23, machine-filled, pseudo-locale | 5, hand-maintained | **Either.** Machine-fill scales; hand-maintenance reads better. Both gate on parity, which is the part that matters. |
| Documentation honesty | Confident throughout | Confident, with a ledger of where it is not | **Younger,** decisively. |

> **[WHY]**

> The older project wins on *enforcement* — the machinery that stops a convention decaying over two years of contributors. The younger wins on *honesty* — the documentation habits that keep a reader correctly calibrated about what is true. Those are complementary, not competing, and neither is a substitute for the other. A codebase with perfect enforcement and confident-but-stale documentation misleads exactly as effectively as one with honest documentation and no enforcement.

<!-- chunk: cmp.adopt | tags: recommendations,summary -->

## If you adopt only five things

1. **A known-gaps section** in your derived documentation, listing every discrepancy between what the docs claim and what you have verified, each marked fixed or outstanding. An hour a quarter. It is the difference between documentation people trust and documentation people route around.
1. **Branch protection codified as data**, with a verify mode. If the live configuration cannot be diffed against a committed target, you do not know what it is.
1. **A release-artifact aliveness test.** Install the shrunk release build on an emulator and assert the process survives fifteen seconds. It catches a class of crash that no unit test can reach.
1. **Static lint tests with ratcheting baselines** for the rules your analyzer cannot express. Forty lines each, adoptable in a legacy codebase without fixing anything first, and they never forget.
1. **Record the failure next to the rule.** Every rule in both projects that survived contact with a new contributor is one whose rationale was written down. The ones that were deleted as inconvenient were the ones where it was not.

> **[CHECK]**

> A quick audit of your own project against this page: can you name, without looking, which of your documented invariants are machine-enforced and which are conventions? If not, that list is your known-gaps section, and writing it is the first item above.

<!-- chunk: cmp.adoption | tags: adoption,status,changelog -->

## Adoption status

This page is an audit of a point in time. What has since been acted on, in the older project, is recorded here rather than by editing the findings above — the finding and its resolution are both useful.

| Recommendation | Status | What landed |
| --- | --- | --- |
| **1.** A known-gaps section | ✅ Adopted | A §22 in the derived overview, with seven verified entries. Two were real: the coverage gate is 40 % rather than the documented 45 %, and it runs only on pushes to the default branch — never on a pull request. Both had been stated incorrectly in three places. |
| **2.** Branch protection codified as data | ✅ Already present, now verified | `--verify` reports `strict=false` and all ten required checks matching the committed target. Recorded in the known-gaps section as a passing check, so the next audit has a baseline. |
| **3.** A release-artifact aliveness test | ✅ Adopted | An advisory workflow builds the R8-shrunk release APK, installs it on an API-34 emulator with a cached AVD snapshot, launches it by explicit component name, and asserts the process survives fifteen seconds *and* logged no fatal exception. Logcat uploads on every outcome. **Not yet executed** — recorded as an outstanding gap. |
| **4.** Static lint tests with ratcheting baselines | ✅ Extended (27th rule) | A ratchet forbidding new hand-rolled `unawaited(errorLogger.log(...))` blocks, with a grandfathered set of twelve files that may only shrink and a pinned length so widening it fails the build. |
| **The guarded-mutation helper** (from the younger project's list) | ✅ Adopted, migrated, **ratchet at zero** | Four helpers — `logFailure`, `guard`, `guardAsync`, `runGuarded` — replacing the seven-line block found in 26 files. 72 call sites migrated by pattern, the remaining 16 (extra context keys, synthetic errors, non-ui layers) by hand; the ratchet's grandfathered set is **empty and pinned at zero**. Fifteen fault-injection tests back the never-throws contract — one added after a second-look review found the helper could throw out of its own catch block when the context had no snackbar-messenger ancestor. `runGuarded` shipped with zero consumers (the exact producer-without-consumer anti-pattern this wiki warns about) and now guards the auto-record persist and the backup-export pipeline. |
| **The three-state hardware availability enum** | ✅ Adopted, generalised, **wired end-to-end** | Applied to Bluetooth rather than NFC, where the same diagnosability gap was worse: an empty OBD2 scan had *five* causes and the app could distinguish two. `Obd2ScanReadiness` resolves all five in priority order, including the silent one — Android location services switched off system-wide, which makes a BLE scan return an empty list with no error anywhere. The second-look review found the first wiring was *dead code*: the scan surfaces an empty window as a timeout *error*, so the empty-state branch was unreachable. It is now wired at three points — a **pre-flight** that resolves the probe before burning a radio-scan window (a blocked user gets the diagnostic instantly, not after a guaranteed-timeout spinner), the timeout error itself, and the defensive empty-list branch. The probe **fails open**: only a positively-identified, non-promptable blocker may divert, because the scan is what triggers the OS permission prompt, and a probe fault must never hide a scan that would have worked. |
| **5.** Record the failure next to the rule | ◐ Ongoing | Every artifact above carries its rationale in a doc comment — the duplication count, the specific bugs the ceremony hid, the field report behind the readiness enum. This is a habit rather than a deliverable. |
| Pinned clocks in tests | ◐ Lower risk than assessed | Re-measured: the older project already injects a `DateTime Function()` seam per class throughout `lib/`, and a scan found no literal month/year assertions of the kind that broke the younger project at a month boundary. The 416 `DateTime.now()` calls in its tests are test-data construction, not assertions. Left as-is. |
| A meaningful coverage ratchet | ⚠ Open | Now documented accurately instead of aspirationally, which is the prerequisite. Raising it, and moving the check somewhere a pull request can see, remains a decision. |

> **[TRAP]**

> **Symptom: an "adopted" practice that was never exercised.** The second-look review of this very adoption pass found three defects in work all tests had blessed: `runGuarded` could throw out of its own catch block (no snackbar-messenger ancestor — the fault-injection suite only ever pumped a full app scaffold); the empty-scan diagnostic was unreachable dead code (the scan reports an empty window as a timeout error, a contract the wiring never checked); and the boot-check workflow referenced `${{ env.ANDROID_SDK_ROOT }}`, which is empty in the expressions context, plus a keystore that does not exist on a fresh runner. All three share one lesson: *green tests prove the paths the tests take*. A helper needs a fault injected at every seam it guards, a UI state needs the trigger that actually produces it, and a workflow has proven nothing until its first real run.

> **[WHY]**

> Because the finding is the reusable part. "The coverage gate says 45 % and enforces 40 %" is worth more to the next reader than a silently corrected number, and the pairing shows what a known-gaps audit actually yields — in this case two live inaccuracies in three documents, found in about ten minutes by checking claims against the files rather than against memory.

#### Sources for this page

- Both repositories as of 2026-08-01: their overview documents, agent-rules files, decision records, CI workflows, lint suites, store metadata and release guides.
- The younger project's known-gaps section, which supplied several of the findings attributed to it here — including the absent branch protection, the date-dependent tests, the coverage-gate assessment, the incomplete licence-header migration and the unverified external integration. Those are its own disclosures, not external criticism.
- The older project's branch-protection script, lint suite, CI topology and libre-audit script.

Counts are as measured on that date and will drift. Verdicts are judgements, argued from the evidence above rather than measured.
