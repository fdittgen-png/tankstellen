<!-- Copyright (c) 2026 Florian DITTGEN -->
<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->

# Independent session review

Every PR to `master` needs another session's review of its current head,
including issue acceptance and actual validation evidence. The author must
not record their own approval or arm a merge before review. This applies to
code, dependency, documentation and CI PRs. Follow-up commits require review
again; an unrelated master update does not invalidate an unchanged head.

GitHub requires `independent-session-review` alongside the existing ten CI
contexts. `strict: false` stays in place: review does not force rebasing.
The check is a commit status, not an additional CI workflow or model call.

## Author

Put exactly one line in the PR body:

```text
Implementation-Session: <stable unique session/thread ID>
```

Automated PRs without this declaration use the origin verified from GitHub's
REST `user.type == "Bot"` and login:
`automated:<owner/repo>/pull/<number>/<login>` (repository/login are lowercased
and `[bot]` becomes `.bot`). This
avoids editing every Dependabot body. A body claiming to be a bot, a bot-like
login on a human account, or `is_bot` alone cannot enable that fallback.
Explicit bot declarations follow the same exactly-one valid identifier rule;
duplicates, blank or malformed declarations are refused. Automation still
needs a real independent session's exact-head review, evidence and status.

Send the repository, PR, full head SHA, issue links and validation evidence
through the shared session message channel. Wait for another session's
findings. Resolve findings in the branch, then request review of the new SHA.

## Reviewer

Read the actual diff, relevant issue body/latest comments and tests. Verify
the claimed behavior, producer/consumer compatibility and acceptance evidence.
Write a report with findings, checked validation, limitations, and an explicit
APPROVE or CHANGES verdict. No findings is a valid result only after review.

Run in the reviewing session:

```sh
python3 scripts/ci/session_review.py --pr 123 --sha <40-character-SHA> \
  --reviewer-session <your-session-ID> --verdict approve --report /tmp/review.md
```

Use `--verdict changes` for unresolved findings. The helper refuses self-review,
missing/ambiguous author identity, a stale SHA, closed PRs and empty evidence.
It posts a GitHub review attached to that commit, rechecks the head, and records
success/failure with a link to the report. Never set this status on behalf of
the implementing session. Only the reviewer can attest their own work.

GitHub authenticates accounts, not local sessions. Sessions sharing the owner
account cannot approve that account's PR through GitHub's separate-user review
rule. This gate therefore uses an explicit session attestation plus a standard
COMMENT review; it does not claim cryptographic separation between holders of
the same credentials. Never invent an identity to approve your own work.

No auto-merge until all required checks pass and the reviewed SHA still matches.
No direct pushes or administrator bypass. Issue closure additionally needs the
complete acceptance evidence and a merged fix (#4339).
