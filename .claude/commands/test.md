Run the full test suite and report results. Usage: `/test` or `/test <path>`

## Steps

1. **Set up environment:**
   ```bash
   export PATH="/c/dev/flutter/bin:$PATH"
   export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-17.0.18.8-hotspot"
   export ANDROID_HOME="$LOCALAPPDATA/Android/Sdk"
   ```

2. **Run tests:**
   - If `$ARGUMENTS` is empty: `flutter test`
   - If `$ARGUMENTS` is a path: `flutter test $ARGUMENTS`
   - If `$ARGUMENTS` is "coverage": `flutter test --coverage`

3. **Parse results:**
   - Count passed, failed, skipped tests
   - List any failing test names with file paths
   - Show total execution time

4. **Report:**
   ```
   TEST RESULTS: X passed, Y failed, Z skipped (Ns)

   FAILURES (if any):
   - file:line — test name — error summary

   PASSED ✓ (or FAILED ✗ with details)
   ```

5. If failures exist:
   - Read the failing test file and the source file it tests
   - Diagnose the root cause
   - Suggest a fix (or fix it if the cause is clear)

## Rules
- Never skip tests or use `--no-sound-null-safety`
- Report pre-existing failures separately from new ones
- If running coverage, filter generated files and report percentage
