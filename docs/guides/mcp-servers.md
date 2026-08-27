# MCP servers for this repo (#3810)

`.mcp.json` at the repo root wires three MCP servers into Claude Code.
Project scope, so the dev setup is versioned instead of living in one
machine's `~/.claude.json`; Claude Code asks for approval the first time
each server is used.

Every entry was probed before being committed — an MCP handshake plus a
`tools/list` — so nothing here is a config that silently fails to start.

## Why these exist

Two structural drags showed up while debugging the OBD2 recording
failures of 2026‑08‑25/26:

1. **Every field diagnosis went through hand-exported JSON.** The user
   exported connect traces, error logs and the driving analysis from
   inside the app and uploaded them. The crash journal, the active-trip
   WAL and logcat were not reachable at all, so `low_memory_kill`
   attribution was inference rather than observation.
2. **`flutter analyze` ran 20+ times at ~80 s each** — roughly half an
   hour of pure waiting — because the CLI cold-starts every invocation.

## `dart` — Dart & Flutter MCP server

Ships **inside the Dart SDK**, so there is nothing to install.

> **Verified 2026-08-27 against `dart mcp-server` version 0.1.4** by probing
> `tools/list` over stdio (recipe at the bottom of this file). Re-probe before
> trusting this list: the tool set changes between builds, and a list copied
> from an upstream README is stale within days (#3837).

**13 tools in 0.1.4:**

| Group | Tools |
|---|---|
| Static analysis | `analyze_files`, `lsp` |
| Packages | `pub`, `pub_dev_search`, `read_package_uris`, `rip_grep_packages` |
| Live app | `dtd`, `widget_inspector`, `get_runtime_errors`, `hot_reload`, `hot_restart`, `flutter_driver_command` |
| Scope | `roots` |

**`analyze_files` is the reason this is wired.** It goes through the
*persistent* analysis server, so it is incremental rather than paying the
~80 s cold start `flutter analyze` costs on every invocation — half an hour
of pure waiting across the 20+ analyze runs of one debugging session.

The **live-app group** is the other real gain: `dtd` → `widget_inspector` +
`get_runtime_errors` reads a RUNNING app instead of reasoning from an
exported JSON, and `hot_reload` applies a change without a rebuild.

### There is no `run_tests` — use `flutter test`

Earlier versions had one and it was the best tool in the set; upstream
removed it. Tests run through the CLI as before.

### `dart_format` and `dart_fix`

`.mcp.json` passes `--exclude-tool dart_format --exclude-tool dart_fix`.
**Those flags are currently no-ops** — both tools are already absent from
0.1.4, and the flags are accepted silently. They are kept as a statement of
intent in case a later build reinstates the tools.

The reason behind them is a **repo rule that stands on its own**, enforced by
convention rather than by the flag: the SDK formatter uses the new **tall**
style, this repo is written in the **short** style, and there is **no format
gate** to catch a mass rewrite. Running it on 2026-08-25 reformatted 20 files
and turned a ~700-line diff into **2 656 lines**, which had to be reverted and
re-applied by hand. Match the surrounding style by hand. See the
`feedback-no-whole-file-dart-format` memory.

Scoped `dart fix` from the CLI is a different matter and remains useful when
an SDK bump introduces lints — one rule at a time, then read the diff:

```sh
dart fix --apply --code=prefer_initializing_formals
git diff --stat
```

#3801 used exactly that for the 224 infos the Dart 3.12 analyzer newly
reports: 222 fixes across 92 files, with no reformatting.

### If a tool name is "not found", look for a rename first

Most disappearances are consolidations: `get_widget_tree` → `widget_inspector`,
`connect_dart_tooling_daemon` → `dtd`, `flutter_driver` →
`flutter_driver_command`, and `hover` / `resolveWorkspaceSymbol` → `lsp` with
a `command` argument.

## `adb` — Android device access

10 tools: `adb_devices`, `adb_logcat`, `adb_pull`, `adb_push`,
`adb_shell`, `adb_install`, `dump_image`, `inspect_ui`,
`adb_activity_manager`, `adb_package_manager`.

This is the one that ends the export-and-upload loop:

- **`adb_pull`** fetches the crash journal (`crash_journal/`) and the
  active-trip WAL (`active_trip_samples.ndjson`) straight off the device.
- **`adb_shell`** reaches `dumpsys` for real `ApplicationExitInfo`
  records, instead of inferring a `low_memory_kill` from breadcrumbs.
- **`dump_image` / `inspect_ui`** capture screen state for UI bugs.

It also makes the #3439 on-device background-recording matrix runnable
without a manual round-trip.

`adb` is **not on the login PATH** on this machine — the config prepends
`${HOME}/android-toolchain/sdk/platform-tools` and sets `ANDROID_HOME`.
Adjust both if the SDK moves.

## `ocr` — independent OCR ground truth

`tesseract` 5.5.3 (Homebrew) plus `mcp-ocr` in an isolated venv at
`~/.claude/mcp-venvs/ocr`. Tools: `perform_ocr`, `image_to_data`,
`perform_pdf_ocr`, `perform_batch_ocr`, `get_supported_languages`.

**This is not for shipping code.** The app's OCR is on-device ML Kit plus
the custom `SevenSegmentRecognizer`. This server exists to read the *same
pump photo a second way*, so a recognizer result can be checked against
independent output rather than reasoned about blind — the #3397 class of
bug, where fixed ROIs could not track a hand-held LCD.

The venv pins **`mcp<2`**: `mcp-ocr` targets the v1 SDK, and v2 renamed
`FastMCP` → `MCPServer`, so an unpinned install dies at import.

### Recreating the venv

```sh
brew install tesseract
python3 -m venv ~/.claude/mcp-venvs/ocr
~/.claude/mcp-venvs/ocr/bin/pip install mcp-ocr "mcp<2"
```

## Already connected, and worth actually using

The **Supabase** connector (claude.ai-managed, no entry needed here) is
authenticated and sees the live `tankstellen` project —
`klelxnkzrxlpzuddhpfg`, the same ref hardcoded in `app_constants.dart`.

HARD RULE #5 is enforced today only by
`test/core/sync/schema_verifier_completeness_test.dart`, which checks the
**code**. A live `list_tables` diff against `schema_verifier.dart` checks
the **deployed** schema, which is where the #2929 silent per-table sync
failures actually come from.

## Deliberately not added

| Candidate | Why not |
|---|---|
| **BLE MCP** | The field adapter is Classic RFCOMM (`lk: "classic"`), which BLE-only tooling cannot speak — and every bug this session was in the app's Dart link-state machine on the phone, not in the dongle. It could characterise a BLE adapter; it cannot reproduce these failures. |
| **OBD2 MCPs** | The published ones are dongle *firmware* (irrelevant) or a virtual CAN/ECU simulator. The simulator would be a nicer fake than `FakeObd2Transport`, but none of this session's defects were protocol parsing — they were ownership, edge-triggered recovery and a missing handshake. |
| **GitHub MCP** | `gh` already covers this with no friction. |

## Verifying a server by hand

```sh
{ printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"1"}}}\n'
  sleep 6
  printf '{"jsonrpc":"2.0","method":"notifications/initialized"}\n'
  sleep 1
  printf '{"jsonrpc":"2.0","id":2,"method":"tools/list"}\n'
  sleep 6
} | <server command>
```

A healthy server answers id 1 with `serverInfo` and id 2 with its tool
list. Config changes need a Claude Code restart to load.
