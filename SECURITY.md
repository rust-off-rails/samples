# Security policy

The samples are auth, sessions, webhooks, jobs and realtime code that apps copy and own. A flaw here spreads to every app that copied the sample, so a sample's `README.md`, `PROMPT.md` or `CHECKS.md` that leads an agent to vulnerable code is a real vulnerability too.

## Reporting a vulnerability

**Please don't open a public issue.** Report privately through GitHub: **Security → Report a vulnerability** on this repository ([private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)).

Useful reports include:
- the sample and file involved;
- what an app with that sample installed is exposed to (a concrete exploit scenario);
- the fix you'd suggest, if any.

We aim to acknowledge reports within 3 business days and to ship a fix as fast as the severity demands, with steps for apps that already copied the sample.

## In scope

- Code, wiring and docs under `samples/`.
- `host/`, the app every sample is tested in.
- `tools/` scripts (`install.sh` copies code into apps).

## Out of scope

An app that changed a sample's code after copying it, and vulnerabilities in third-party crates and packages: report those upstream, then tell us if a sample should drop or pin something. The framework itself (guides, generators, the template app, the installer) has its own policy in [rust-off-rails/rustoffrails](https://github.com/rust-off-rails/rustoffrails/blob/main/SECURITY.md).

## Supported versions

The latest release. Apps pick up a fixed sample with `cargo offrails add <part>` from an upgraded framework, or by copying the change.
