Find untested files and suggest what tests to write next.

## Steps

1. **Scan lib/ for all source files** (excluding .g.dart, .freezed.dart, l10n/):
   ```bash
   find lib/ -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" ! -path "*/l10n/*" | sort
   ```

2. **Scan test/ for all test files:**
   ```bash
   find test/ -name "*_test.dart" | sort
   ```

3. **Cross-reference:** For each lib/ file, check if a corresponding test file exists.
   Map `lib/features/X/Y/Z.dart` → `test/features/X/Y/Z_test.dart`.

4. **Categorize untested files by risk:**

   | Risk | Category | Examples |
   |------|----------|---------|
   | Critical | Services, providers, repositories | State management, API calls, data persistence |
   | High | Screens, complex widgets | User-facing, interaction-heavy |
   | Medium | Utilities, helpers, extensions | Shared logic, formatting |
   | Low | Constants, configs, models | No logic, generated |

5. **Report:**
   ```
   UNTESTED FILES: X of Y lib files have no corresponding test

   CRITICAL (write tests immediately):
   - lib/path/to/file.dart — reason

   HIGH (write tests soon):
   - lib/path/to/file.dart — reason

   MEDIUM:
   - ...

   LOW (skip or defer):
   - ...

   COVERAGE: Run `/test coverage` for line-level coverage.
   ACTION: Run `/test-write <file>` to write tests for a specific file.
   ```

## Rules
- Do NOT modify any files — this command is read-only
- Group results by feature area (core/, features/search/, etc.)
- Highlight files that have been recently modified (check git log)
