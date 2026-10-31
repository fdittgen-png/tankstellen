#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Publish an independent session's exact-commit review (#4339, #4451).

Run ONLY in the reviewing session after reviewing the diff and acceptance.
GitHub cannot distinguish sessions using the same account; the signed-in
reviewer attests their session identity. This is a process gate, not identity
isolation from another holder of the same GitHub credentials.
"""

import argparse
import json
from pathlib import Path
import re
import subprocess

CONTEXT = "independent-session-review"
SESSION_LINE = re.compile(r"^Implementation-Session:[ \t]*(\S+)[ \t]*$", re.MULTILINE)
SESSION_ID = re.compile(r"[A-Za-z0-9._:/-]{3,160}")
DECLARATION = re.compile(r"^[ \t]*Implementation-Session\b[^\n]*$", re.MULTILINE)


def implementation_session(pr, repo, pr_number):
    body = pr.get("body") or ""
    declarations = DECLARATION.findall(body)
    authors = SESSION_LINE.findall(body)
    if declarations:
        if len(declarations) != 1 or len(authors) != 1:
            raise ValueError("PR body must declare exactly one Implementation-Session")
        if not SESSION_ID.fullmatch(authors[0]):
            raise ValueError("Malformed Implementation-Session identifier")
        return authors[0]
    # Only authenticated REST metadata identifies an automated author. Body
    # claims, login spelling and the GraphQL is_bot hint are not this proof.
    user = pr.get("user") or {}
    login = user.get("login", "") if isinstance(user, dict) else ""
    if (isinstance(user, dict) and user.get("type") == "Bot"
            and isinstance(login, str) and re.fullmatch(
            r"[A-Za-z0-9][A-Za-z0-9_-]*(?:\[bot\])?", login)):
        return "automated:{}/pull/{}/{}".format(
            repo.lower(), pr_number, login.lower().replace("[bot]", ".bot"))
    raise ValueError("PR body must declare exactly one Implementation-Session")


def gh_api(endpoint, method="GET", payload=None):
    command = ["gh", "api", endpoint, "--method", method]
    if payload is not None:
        command += ["--input", "-"]
    result = subprocess.run(
        command, input=None if payload is None else json.dumps(payload),
        text=True, capture_output=True, check=True,
    )
    return json.loads(result.stdout)


def publish_review(repo, pr_number, sha, reviewer_session, verdict, report, api=gh_api):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("Use the full 40-character reviewed commit SHA")
    if not SESSION_ID.fullmatch(reviewer_session):
        raise ValueError("Use a stable, unique reviewer session identifier")
    if len(report.strip()) < 40:
        raise ValueError("Include findings, validation and issue-acceptance evidence")
    if verdict not in ("approve", "changes"):
        raise ValueError("Verdict must be approve or changes")
    endpoint = "repos/{}/pulls/{}".format(repo, pr_number)
    pr = api(endpoint)
    author = implementation_session(pr, repo, pr_number)
    if author == reviewer_session:
        raise ValueError("The implementation session cannot review its own PR")
    if pr["head"]["sha"] != sha or pr["state"] != "open":
        raise ValueError("Review is stale or PR is no longer open; review the current head")
    body = (
        "Independent session review: **{}**\n\n"
        "Implementation-Session: {}\nReviewer-Session: {}\nReviewed-Head: {}\n\n{}"
    ).format(verdict.upper(), author, reviewer_session, sha, report.strip())
    # COMMENT permits independent sessions sharing the PR author's account.
    # It is deliberately not presented as a second GitHub user's approval.
    review = api(endpoint + "/reviews", "POST", {
        "commit_id": sha, "event": "COMMENT", "body": body,
    })
    current = api(endpoint)
    if current["head"]["sha"] != sha or current["state"] != "open":
        raise ValueError("PR changed while publishing; no passing status was recorded")
    status = api("repos/{}/statuses/{}".format(repo, sha), "POST", {
        "state": "success" if verdict == "approve" else "failure",
        "context": CONTEXT,
        "description": "Independent session approved this SHA" if verdict == "approve"
            else "Independent session requested changes",
        "target_url": review["html_url"],
    })
    return status["target_url"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default="fdittgen-png/tankstellen")
    parser.add_argument("--pr", required=True, type=int)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--reviewer-session", required=True)
    parser.add_argument("--verdict", choices=("approve", "changes"), required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    print(publish_review(args.repo, args.pr, args.sha, args.reviewer_session,
                         args.verdict, args.report.read_text()))


if __name__ == "__main__":
    main()
