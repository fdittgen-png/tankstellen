#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Validate git pre-push ref records before expensive generation starts."""
import subprocess
import sys


def validate(branch, records):
    for record in records.splitlines():
        local_ref, local_sha, remote_ref, _ = record.split()
        if not local_sha.strip('0') or not remote_ref.startswith('refs/heads/'):
            continue  # deletions and release tags do not push a working branch
        if remote_ref == 'refs/heads/master':
            raise ValueError('push a feature branch and open a PR; master is protected')
        expected = 'refs/heads/' + branch
        if not branch or local_ref != expected or remote_ref != expected:
            raise ValueError(f'current branch is {branch!r}; refusing {local_ref} -> {remote_ref}')


def main():
    branch = subprocess.check_output(['git', 'branch', '--show-current'], text=True).strip()
    try:
        validate(branch, sys.stdin.read())
    except ValueError as error:
        print(f'pre-push branch guard: {error}', file=sys.stderr)
        raise SystemExit(1)


if __name__ == '__main__':
    main()
