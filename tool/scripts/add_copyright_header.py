#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT
"""Add a 2-line MIT SPDX copyright header to every hand-written source
file in the repo (#2053).

Idempotent: skips files whose first 5 lines already contain
"Copyright (c) 2026 Florian DITTGEN". Adapts the comment delimiter to
the file's language. Preserves shebangs (`#!/...`) and XML
declarations (`<?xml ?>`) — the header lands immediately after them.

Out of scope (paths skipped wholesale):
  - generated code: *.g.dart, *.freezed.dart, *.gen.dart, *.mocks.dart,
    *.config.dart, *.pb.dart
  - vendored / third-party: vendor/, Pods/, node_modules/, .dart_tool/,
    ios/Flutter/, ios/Runner.xcworkspace/
  - build outputs + IDE: build/, .gradle/, .idea/, .vscode/
  - lockfiles + LICENSE itself + binary assets

Usage:
  python3 tool/scripts/add_copyright_header.py [--dry-run]
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

HEADER_LINES = (
    "Copyright (c) 2026 Florian DITTGEN",
    "SPDX-License-Identifier: MIT",
)

MARKER = HEADER_LINES[0]

SKIP_DIR_PARTS = {
    ".dart_tool",
    "build",
    ".gradle",
    ".idea",
    ".vscode",
    "vendor",
    "Pods",
    "node_modules",
    "Flutter",
    "Runner.xcworkspace",
    "Runner.xcodeproj",
    ".git",
    "ephemeral",
    "DerivedData",
    ".symlinks",
    "Generated.xcconfig",
    ".fvm",
    ".flutter-plugins-dependencies",
}

SKIP_FILE_SUFFIXES = (
    ".g.dart",
    ".freezed.dart",
    ".gen.dart",
    ".mocks.dart",
    ".config.dart",
    ".pb.dart",
    ".pbenum.dart",
    ".pbjson.dart",
    ".pbserver.dart",
)

SKIP_FILE_NAMES = {
    "LICENSE",
    # Golden fixture XML — the BackupXmlWriter test compares its output
    # byte-for-byte to this file; the writer emits no header, so the
    # fixture cannot carry one either (#2053 follow-up).
    "sample_backup_v1.xml",
    "pubspec.lock",
    "Gemfile.lock",
    "Podfile.lock",
    "package-lock.json",
    "yarn.lock",
    ".flutter-plugins-dependencies",
    ".flutter-plugins",
    ".packages",
    ".metadata",
    "Generated.xcconfig",
    "flutter_export_environment.sh",
}

EXT_COMMENT: dict[str, tuple[str, str, str]] = {
    # ext: (open, line-prefix, close)  — empty open/close means line comments
    ".dart": ("", "// ", ""),
    ".kt": ("", "// ", ""),
    ".kts": ("", "// ", ""),
    ".java": ("", "// ", ""),
    ".gradle": ("", "// ", ""),
    ".groovy": ("", "// ", ""),
    ".swift": ("", "// ", ""),
    ".m": ("", "// ", ""),
    ".mm": ("", "// ", ""),
    ".h": ("", "// ", ""),
    ".c": ("", "// ", ""),
    ".cc": ("", "// ", ""),
    ".cpp": ("", "// ", ""),
    ".cxx": ("", "// ", ""),
    ".hpp": ("", "// ", ""),
    ".js": ("", "// ", ""),
    ".mjs": ("", "// ", ""),
    ".cjs": ("", "// ", ""),
    ".ts": ("", "// ", ""),
    ".tsx": ("", "// ", ""),
    ".jsx": ("", "// ", ""),
    ".rs": ("", "// ", ""),
    ".go": ("", "// ", ""),
    ".dart_test_config": ("", "// ", ""),
    # Hash-comment family
    ".sh": ("", "# ", ""),
    ".bash": ("", "# ", ""),
    ".zsh": ("", "# ", ""),
    ".py": ("", "# ", ""),
    ".rb": ("", "# ", ""),
    ".pl": ("", "# ", ""),
    ".yml": ("", "# ", ""),
    ".yaml": ("", "# ", ""),
    ".toml": ("", "# ", ""),
    ".cfg": ("", "# ", ""),
    ".conf": ("", "# ", ""),
    ".ini": ("", "# ", ""),
    ".pro": ("", "# ", ""),
    ".gitignore": ("", "# ", ""),
    ".gitattributes": ("", "# ", ""),
    ".editorconfig": ("", "# ", ""),
    ".env": ("", "# ", ""),
    ".env.example": ("", "# ", ""),
    # HTML/XML family
    ".html": ("<!--", "  ", "-->"),
    ".htm": ("<!--", "  ", "-->"),
    ".xml": ("<!--", "  ", "-->"),
    ".svg": ("<!--", "  ", "-->"),
    ".md": ("<!--", "  ", "-->"),
    ".markdown": ("<!--", "  ", "-->"),
    ".plist": ("<!--", "  ", "-->"),
    ".storyboard": ("<!--", "  ", "-->"),
    ".xib": ("<!--", "  ", "-->"),
    ".arb": ("", "", ""),  # JSON-only — no comment syntax, skip
    # CSS family
    ".css": ("/*", " * ", " */"),
    ".scss": ("/*", " * ", " */"),
    ".sass": ("/*", " * ", " */"),
    ".less": ("/*", " * ", " */"),
}

# Filenames without an extension that we still want headed.
HASH_COMMENT_FILENAMES = {
    "Dockerfile",
    "Makefile",
    "Fastfile",
    "Appfile",
    "Matchfile",
    "Pluginfile",
    "Gemfile",
    "Podfile",
    "Brewfile",
    "Procfile",
    "Justfile",
}


def comment_block_for(path: Path) -> list[str] | None:
    """Return the header lines for this file, or None if the file type
    has no comment syntax / isn't supported."""
    suffix = path.suffix.lower()

    # JSON ARB doesn't support comments — skip silently.
    if suffix == ".arb" or suffix == ".json":
        return None

    spec = EXT_COMMENT.get(suffix)
    if spec is None and path.name in HASH_COMMENT_FILENAMES:
        spec = ("", "# ", "")

    if spec is None:
        return None

    open_, prefix, close = spec
    lines: list[str] = []
    if open_:
        lines.append(open_)
    for h in HEADER_LINES:
        lines.append(f"{prefix}{h}".rstrip())
    if close:
        lines.append(close)
    return lines


def should_skip_path(path: Path) -> bool:
    if path.name in SKIP_FILE_NAMES:
        return True
    if any(part in SKIP_DIR_PARTS for part in path.parts):
        return True
    n = path.name
    for suf in SKIP_FILE_SUFFIXES:
        if n.endswith(suf):
            return True
    return False


def has_marker(text: str) -> bool:
    head = "\n".join(text.splitlines()[:5])
    return MARKER in head


def is_text_file(path: Path) -> bool:
    try:
        with path.open("rb") as f:
            chunk = f.read(8192)
        if b"\0" in chunk:
            return False
        chunk.decode("utf-8")
        return True
    except (UnicodeDecodeError, OSError):
        return False


def insert_after_preamble(text: str, header: list[str]) -> str:
    """Insert `header` after a shebang or XML declaration if present,
    otherwise at the very top."""
    lines = text.splitlines(keepends=True)
    insert_at = 0
    if lines and lines[0].startswith("#!"):
        insert_at = 1
    elif lines and lines[0].lstrip().startswith("<?xml"):
        insert_at = 1
    block = "\n".join(header) + "\n"
    # Add a blank line between the header and the body unless the next
    # line is already blank.
    if insert_at < len(lines) and lines[insert_at].strip():
        block += "\n"
    return "".join(lines[:insert_at]) + block + "".join(lines[insert_at:])


def process(path: Path, dry_run: bool) -> str:
    """Return one of: 'updated', 'skip-marker', 'skip-binary',
    'skip-type', 'skip-empty'."""
    header = comment_block_for(path)
    if header is None:
        return "skip-type"
    if not is_text_file(path):
        return "skip-binary"
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return "skip-binary"
    # Strip UTF-8 BOM (U+FEFF) so the header can land at byte 0 without
    # the BOM ending up mid-file and tripping the Dart parser's
    # `illegal_character 65279` rule.
    if text.startswith("﻿"):
        text = text.lstrip("﻿")
    if not text.strip():
        return "skip-empty"
    if has_marker(text):
        return "skip-marker"
    new_text = insert_after_preamble(text, header)
    if not dry_run:
        path.write_text(new_text, encoding="utf-8")
    return "updated"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("paths", nargs="*", default=[])
    args = parser.parse_args()

    if args.paths:
        targets = [Path(p).resolve() for p in args.paths]
    else:
        targets = [REPO_ROOT]

    counts = {
        "updated": 0,
        "skip-marker": 0,
        "skip-binary": 0,
        "skip-type": 0,
        "skip-empty": 0,
    }
    updated_files: list[Path] = []

    for root in targets:
        if root.is_file():
            files = [root]
        else:
            files = []
            for dirpath, dirnames, filenames in os.walk(root):
                # Prune skip dirs in-place so we don't descend into them.
                dirnames[:] = [d for d in dirnames if d not in SKIP_DIR_PARTS]
                for fn in filenames:
                    files.append(Path(dirpath) / fn)
        for path in files:
            if should_skip_path(path):
                counts["skip-type"] += 1
                continue
            result = process(path, args.dry_run)
            counts[result] += 1
            if result == "updated":
                updated_files.append(path)

    print(f"updated     : {counts['updated']}")
    print(f"skip-marker : {counts['skip-marker']}")
    print(f"skip-binary : {counts['skip-binary']}")
    print(f"skip-type   : {counts['skip-type']}")
    print(f"skip-empty  : {counts['skip-empty']}")
    if args.dry_run and updated_files:
        print("\nWould update (first 20):")
        for p in updated_files[:20]:
            print(f"  {p.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
