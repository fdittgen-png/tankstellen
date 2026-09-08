# Workflow naming convention (#3972)

GitHub sorts the **Actions** sidebar alphabetically by workflow name. With 27
workflows that only reads well if the name itself carries the grouping, so
every workflow here is named:

```
<Group> · <what it does, sentence case>
```

## The six groups

Ordered by when you care about them, which is also how they cluster in the
sidebar:

| Group | Meaning | Who triggers it |
| --- | --- | --- |
| `CI` | gates a PR or a push to master | automatic |
| `Nightly` | scheduled health checks | cron |
| `Release` | ships a build to users | cron or maintainer |
| `Publish` | pushes non-app artefacts — site, listings, data | cron or maintainer |
| `Status` | read-only queries; changes nothing | maintainer |
| `Tools` | manual maintenance utilities | maintainer |

## Rules

- Sentence case after the group — `Regenerate lockfiles`, not
  `Regenerate Lockfiles`.
- Verb-first when the workflow *performs* an action
  (`Add iOS TestFlight tester`); noun-first when it names what it produces or
  reports on (`Play track`, `Motorway exits`).
- `F-Droid` is always spelled that way — never `fdroid` in a display name.
- A parenthetical only for a real disambiguator: `(daily)`, `(arm64)`,
  `(all stores)`. Not for an explanation.
- Two workflows must never share a name. `ci.yml` and `ci-docs-stub.yml` were
  both literally `CI` and were indistinguishable in every run list.

Both rules that can be checked mechanically are enforced by
`test/ci/ci_workflow_test.dart` (`workflow naming convention (#3972)`).

## What this convention does *not* touch

Workflow names are **not** status-check contexts. Branch protection lists bare
job ids — `analyze`, `test (0)`, `build-android`, … — so renaming a workflow is
free, while renaming a **job** changes a required context and can block
auto-merge forever if protection is not updated in lockstep. `ci-docs-stub.yml`
exists precisely to re-emit those contexts for docs-only changes, so its job
names must keep mirroring `ci.yml`'s exactly.

`workflow_call` references resolve by path (`./.github/workflows/x.yml`), so
they are unaffected by a rename too.
