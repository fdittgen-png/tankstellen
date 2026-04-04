Write tests for a specific file or feature. Usage: `/test-write <file-or-feature>`

## Steps

1. **Identify the target.** If `$ARGUMENTS` is:
   - A file path (e.g., `lib/core/cache/cache_manager.dart`) → write tests for that file
   - A feature name (e.g., `favorites`, `alerts`) → write tests for all untested files in that feature
   - Empty → ask the user what to test

2. **Read the source file(s).** Understand:
   - Public API (methods, properties, constructors)
   - Dependencies (what it imports, what providers it uses)
   - Edge cases (null handling, error paths, boundary conditions)
   - Existing tests (check if a test file already exists)

3. **Determine test type:**
   - **Provider/service/repository** → Unit test with fakes/mocks
   - **Screen/page** → Widget test with `pumpApp` + provider overrides
   - **Widget** → Widget test verifying rendering + interactions
   - **Utility/model** → Unit test with direct assertions

4. **Write the test file** following project conventions:
   - Place in matching directory under `test/` (mirror the `lib/` structure)
   - Use `mocktail` for mocks, prefer fakes for complex services
   - Use `pumpApp` from `test/helpers/pump_app.dart` for widget tests
   - Use `standardTestOverrides` from `test/helpers/mock_providers.dart`
   - Use test fixtures from `test/fixtures/` where available
   - Group tests logically with `group()`
   - Name tests descriptively: "returns empty list when no favorites"

5. **Test categories to include:**
   - Happy path (normal operation)
   - Empty/null states
   - Error handling (exceptions, network failures)
   - Edge cases (boundary values, concurrent access)
   - For widgets: accessibility (`meetsGuideline(androidTapTargetGuideline)`)

6. **Run the tests:**
   ```bash
   export PATH="/c/dev/flutter/bin:$PATH"
   flutter test <test-file-path>
   ```

7. **Fix any failures** and re-run until all pass.

8. **Report:**
   ```
   TESTS WRITTEN: <test-file-path>
   - X tests in Y groups
   - All passing ✓

   Coverage: <methods/paths tested>
   ```

## Rules
- **Always read the source file before writing tests** — never guess the API
- **Every test must pass** — fix failures before reporting
- **Prefer fakes over mocks** for service layer tests
- **Test behavior, not implementation** — don't assert on internal state
- **No silent `catch (_) {}`** in test helpers — always log errors
- **Use `const` constructors** where possible in test fixtures
- Screens must stay under 300 lines, split into multiple test groups if needed
