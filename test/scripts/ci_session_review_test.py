# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later

import copy
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts/ci"))

from session_review import publish_review

SHA = "a" * 40
REPORT = "Reviewed diff and issue acceptance. Regression tests pass. No findings."


class FakeGitHub:
    def __init__(self):
        self.pr = {"state": "open", "head": {"sha": SHA},
                   "body": "Implementation-Session: author-thread"}
        self.writes = []
        self.advance_after_review = False

    def __call__(self, endpoint, method="GET", payload=None):
        if method == "GET":
            return copy.deepcopy(self.pr)
        self.writes.append((endpoint, payload))
        if endpoint.endswith("/reviews"):
            if self.advance_after_review:
                self.pr["head"]["sha"] = "b" * 40
            return {"html_url": "https://github.com/example/repo/pull/1#review-2"}
        return payload


class SessionReviewTests(unittest.TestCase):
    def run_review(self, api, **overrides):
        args = dict(repo="example/repo", pr_number=1, sha=SHA,
                    reviewer_session="reviewer-thread", verdict="approve",
                    report=REPORT, api=api)
        args.update(overrides)
        return publish_review(**args)

    def test_approval_is_attached_to_reviewed_commit_and_evidence(self):
        api = FakeGitHub()
        url = self.run_review(api)
        self.assertEqual(api.writes[0][1]["commit_id"], SHA)
        self.assertEqual(api.writes[0][1]["event"], "COMMENT")
        self.assertIn("Reviewer-Session: reviewer-thread", api.writes[0][1]["body"])
        endpoint, status = api.writes[1]
        self.assertTrue(endpoint.endswith("/statuses/" + SHA))
        self.assertEqual(status["state"], "success")
        self.assertEqual(status["target_url"], url)

    def test_changes_record_failure(self):
        api = FakeGitHub()
        self.run_review(api, verdict="changes")
        self.assertEqual(api.writes[-1][1]["state"], "failure")

    def test_self_review_is_rejected_without_writes(self):
        api = FakeGitHub()
        with self.assertRaisesRegex(ValueError, "own PR"):
            self.run_review(api, reviewer_session="author-thread")
        self.assertEqual(api.writes, [])

    def test_missing_or_ambiguous_author_is_rejected(self):
        for body in ("", "Implementation-Session: a\nImplementation-Session: b"):
            api = FakeGitHub()
            api.pr["body"] = body
            with self.assertRaisesRegex(ValueError, "exactly one"):
                self.run_review(api)
            self.assertEqual(api.writes, [])

    def test_verified_bot_without_declaration_has_stable_automated_origin(self):
        api = FakeGitHub()
        api.pr.update(body="Dependency update", user={
            "type": "Bot", "login": "dependabot[bot]"})
        self.run_review(api)
        self.assertIn(
            "Implementation-Session: automated:example/repo/pull/1/dependabot.bot",
            api.writes[0][1]["body"])
        self.assertEqual(api.writes[-1][1]["state"], "success")

    def test_automated_origin_still_cannot_review_itself(self):
        api = FakeGitHub()
        api.pr.update(body="", user={"type": "Bot", "login": "dependabot[bot]"})
        with self.assertRaisesRegex(ValueError, "own PR"):
            self.run_review(api, reviewer_session=
                            "automated:example/repo/pull/1/dependabot.bot")
        self.assertEqual(api.writes, [])

    def test_body_or_login_claims_cannot_spoof_rest_bot_metadata(self):
        for user in ({}, {"type": "User", "login": "dependabot[bot]"},
                     {"is_bot": True, "login": "dependabot[bot]"},
                     {"type": "bot", "login": "dependabot[bot]"},
                     {"type": "Bot", "login": "bad/login"}):
            api = FakeGitHub()
            api.pr.update(body='I am a bot: {"type":"Bot"}', user=user)
            with self.assertRaises(ValueError):
                self.run_review(api)
            self.assertEqual(api.writes, [])

    def test_bot_duplicate_or_malformed_declaration_cannot_fall_back(self):
        for body in ("Implementation-Session:",
                     "Implementation-Session:\nmisleading-next-line",
                     "Implementation-Session: invalid!",
                     "Implementation-Session: author-thread\nImplementation-Session:",
                     "Implementation-Session: author-thread\nImplementation-Session: other"):
            api = FakeGitHub()
            api.pr.update(body=body, user={"type": "Bot", "login": "dependabot[bot]"})
            with self.assertRaises(ValueError):
                self.run_review(api)
            self.assertEqual(api.writes, [])

    def test_human_malformed_declaration_is_rejected(self):
        for body in ("Implementation-Session: author-thread\nImplementation-Session:",
                     "Implementation-Session:\nmisleading-next-line"):
            api = FakeGitHub()
            api.pr["body"] = body
            with self.assertRaises(ValueError):
                self.run_review(api)
            self.assertEqual(api.writes, [])

    def test_stale_or_closed_pr_is_rejected_without_writes(self):
        for field in ("head", "state"):
            api = FakeGitHub()
            api.pr[field] = {"sha": "b" * 40} if field == "head" else "closed"
            with self.assertRaisesRegex(ValueError, "stale"):
                self.run_review(api)
            self.assertEqual(api.writes, [])

    def test_push_during_publication_does_not_record_passing_status(self):
        api = FakeGitHub()
        api.advance_after_review = True
        with self.assertRaisesRegex(ValueError, "changed while publishing"):
            self.run_review(api)
        self.assertEqual(len(api.writes), 1)
        self.assertTrue(api.writes[0][0].endswith("/reviews"))

    def test_short_sha_or_empty_evidence_is_rejected(self):
        for overrides in ({"sha": "abc1234"}, {"report": "LGTM"},
                          {"reviewer_session": ""}, {"verdict": "other"}):
            api = FakeGitHub()
            with self.assertRaises(ValueError):
                self.run_review(api, **overrides)
            self.assertEqual(api.writes, [])


if __name__ == "__main__":
    unittest.main()
