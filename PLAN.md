# Rust off Rails samples: plan for 0.7.0

These are tested reference implementations of the parts every Rust off Rails app needs. The framework only **points at** them; nothing here is mandatory. An agent copies a sample into its app and adapts it, and from then on the app owns that code. Every sample is versioned with the framework (tag `v0.7.0`). Serving them from rustoffrails.org/samples and the site's MCP server (`list_samples`, `get_sample`, `diff_sample`) is planned, not live yet (step 4).

## Layout

```
host/                 A blank app exactly as `generators/new.md` (framework 0.7.0) produces it: config, db (SQLite + Postgres),
                      sessions/CSRF/flash, security headers, layout, error pages, tests/app/support.rs. Every sample installs into it.
samples/<name>/
  sample.toml         name, summary, depends_on, crates (`cargo add` lines), files (src -> app path), wiring snippets
                      (routes.rs, mod.rs, migration/src/lib.rs, main.rs), env vars, migrations
  README.md           What it is, an exact install procedure for an agent, wiring, what to rename or customize
  CHECKS.md           What "working and safe" means: a threat model (STRIDE), invariants, and the tests/commands that prove each one
  files/...           The code, laid out at its app paths (src/, templates/, static/, migration/, tests/)
tools/install.sh      install.sh <sample> <app-dir>: does what an agent does by hand (resolves depends_on, copies files, applies wiring)
tools/ci.sh           For each sample, and for "all": fresh copy of host/ + install + fmt + clippy + tests on SQLite AND Postgres + offrails-check
```

## Samples (0.7.0)

| Sample | Depends on | Summary |
|---|---|---|
| `mailer` | — | Mailer (templated HTML + text), delivery adapters (dev mailbox, SMTP, log), previews |
| `dev-mailbox` | mailer | A local mailbox at `/dev/mailbox`: live inbox (SSE), HTML/text/raw/headers, desktop/mobile/dark previews, extracted links and codes, attachments, search, clear, `.eml` download. Dev-only, never routed in production. |
| `jobs` | — | A DB-backed job queue (Oban-style): Postgres `FOR UPDATE SKIP LOCKED`, SQLite single-writer claim, retries with backoff and jitter, unique jobs, priorities, scheduled and cron jobs, timeouts, rescue of orphaned jobs, graceful shutdown, pruning |
| `jobs-dashboard` | jobs | `/admin/jobs`: overview, queues, states, job detail with errors and args, retry/cancel/discard, cron, live refresh; admin-only |
| `webhooks` | jobs | Signed inbound webhooks: `POST /webhooks/{provider}` verifies the HMAC over the raw body (GitHub and Stripe schemes) in constant time, refuses stale timestamps, stores each event once (a replay is a no-op), and does the work in a job; a provider without a secret answers 404 |
| `auth-password` | mailer | Email + password: argon2id, signup, email verification, login, logout, password reset, session rotation, rate limits and lockout, no user enumeration |
| `auth-magic-link` | mailer | Passwordless sign-in: single-use, hashed, short-lived tokens; "check your mailbox" hint in dev |
| `auth-totp` | auth-password or auth-magic-link | TOTP 2FA (RFC 6238): enrol with QR code, verify, recovery codes, step-up on sensitive actions, replay protection |
| `realtime` | (an auth sample) | Channels over WebSocket (offrails v1 protocol), topic authorization on join, presence, SSE fallback, signed socket tokens, per-user caps, tuned buffers |

## Phases

1. **Foundation:** `host/`, the sample format, `tools/install.sh`, `tools/ci.sh`, and `mailer` + `dev-mailbox` built end to end. These set the pattern.
2. **In parallel, one owner per sample folder** (`host/` is frozen; changes to it go through the coordinator):
   - jobs + jobs-dashboard;
   - auth-password + auth-magic-link + auth-totp;
   - realtime.
3. **Framework 0.7.0:** each relevant guide gets a one-line optional pointer, `generators/new.md` gets an optional "head start" step, `CHANGELOG`, and an `offrails-check` hint.
4. **Website (not done yet; coming after the release):** `/samples` pages, a raw `.tar.gz` per sample with a checksum, MCP tools `list_samples` / `get_sample` / `diff_sample`, and checksum-verified fetching per release.
5. **Release** framework 0.7.0 and samples v0.7.0.

## Rules

- Source material: code extracted from Rust off Rails apps (jobs, mailbox, magic links, security, realtime). Improve on it; don't copy its bugs.
- Every sample passes the framework's Definition of Done in the host, on SQLite and on Postgres, alone and together with all the others.
- Security-critical samples (auth-*, realtime, jobs-dashboard) have a STRIDE table in `CHECKS.md` and a test for every mitigation.
