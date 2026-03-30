# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 4.x     | Yes       |
| < 4.0   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

### How to Report

1. **Email:** Send a detailed report to **florian@dittgen.dev**
2. **Subject line:** `[SECURITY] Tankstellen — <brief description>`
3. **Include:**
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

| Severity | Response Time | Fix Target |
|----------|---------------|------------|
| Critical (data leak, RCE) | 24 hours | 48 hours |
| High (auth bypass, injection) | 48 hours | 1 week |
| Medium (info disclosure) | 1 week | 2 weeks |
| Low (minor issue) | 2 weeks | Next release |

### Process

1. **Acknowledgment** — You'll receive a confirmation within the response time above
2. **Assessment** — The issue will be evaluated for severity and impact
3. **Fix** — A patch will be developed and tested
4. **Disclosure** — Once fixed, the vulnerability will be disclosed in the release notes with credit to the reporter (unless anonymity is requested)

## Security Design Principles

This project follows these security practices:

- **No API keys in source code** — users provide their own keys, stored in platform-specific secure storage (Android Keystore / iOS Keychain)
- **No tracking or analytics** — no Firebase, no Google Play Services, no ad SDKs
- **Minimal permissions** — only location (for nearby search) and internet (for API calls)
- **No PII collection** — anonymous auth only, no email required
- **Input validation** — all user input sanitized (URLs, postal codes, search queries)
- **Dependency auditing** — all dependencies must be MIT/BSD/Apache licensed, reviewed monthly via `dart pub outdated`
- **HTTPS only** — all API communication over TLS

## Scope

The following are **in scope** for security reports:

- The Tankstellen mobile app (Android/iOS)
- TankSync backend (Supabase Edge Functions, RLS policies)
- CI/CD pipeline security (GitHub Actions workflows)
- Dependencies with known CVEs

The following are **out of scope:**

- Third-party fuel price APIs (report to the respective government agency)
- OpenStreetMap tile servers
- Supabase platform infrastructure (report to Supabase)
