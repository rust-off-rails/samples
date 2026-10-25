# Rust off Rails samples

Tested reference code for the parts every [Rust off Rails](https://rustoffrails.org) app needs: a mailer, a dev mailbox, a job queue and its dashboard, signed inbound webhooks, accounts, realtime, and a dev dashboard. An agent copies a sample into its app and adapts it; from then on the app owns that code. Nothing here is a dependency, and nothing is mandatory: the framework's guides describe each part, and a sample is the version that was built, tested on SQLite and Postgres, and reviewed for security.

Every sample follows the framework's conventions exactly (stack, layout, naming, the Definition of Done), so copied code looks like code the agent would have written. Comments mark what to change (`// APP:`), what to keep and why (`// WHY:`, `// INVARIANT:`, `// SECURITY:`), and the guide section it implements (`// GUIDE:`), so even a small model adapts a sample safely ([format](samples/FORMAT.md#comments-that-guide-the-next-model)).

<a href="docs/screenshots/dev-dashboard/overview-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dev-dashboard/overview-dark-desktop.png"><img src="docs/screenshots/dev-dashboard/overview-light-desktop.png" alt="dev-dashboard: the overview with live cards, sparklines, insights, the slowest routes and queries" width="860"></picture></a>

<sub><b>dev-dashboard</b> at <code>/dev/dashboard</code>: memory, CPU, req/s, latency, SQL and the pool live, with the insights that matter. In-process, nothing else to run.</sub>

<table>
<tr><td valign="top" width="50%"><a href="docs/screenshots/dev-dashboard/charts-readout-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dev-dashboard/charts-readout-dark-desktop.png"><img src="docs/screenshots/dev-dashboard/charts-readout-light-desktop.png" alt="dev-dashboard: live charts with one crosshair across every chart" width="420"></picture></a><br><sub><b>dev-dashboard</b>: live charts, one crosshair across all</sub></td><td valign="top" width="50%"><a href="docs/screenshots/dev-dashboard/ai-run-done-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dev-dashboard/ai-run-done-dark-desktop.png"><img src="docs/screenshots/dev-dashboard/ai-run-done-light-desktop.png" alt="dev-dashboard: Ask AI investigates an N+1 and proposes the fix and a test" width="420"></picture></a><br><sub><b>dev-dashboard</b>: Ask AI investigates an N+1 (your own key)</sub></td></tr>
<tr><td valign="top" width="50%"><a href="docs/screenshots/dev-dashboard/erd-focus-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dev-dashboard/erd-focus-dark-desktop.png"><img src="docs/screenshots/dev-dashboard/erd-focus-light-desktop.png" alt="dev-dashboard: the schema as an interactive diagram, a table in focus" width="420"></picture></a><br><sub><b>dev-dashboard</b>: the schema as an interactive ERD</sub></td><td valign="top" width="50%"><a href="docs/screenshots/dev-mailbox/inbox-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dev-mailbox/inbox-dark-desktop.png"><img src="docs/screenshots/dev-mailbox/inbox-light-desktop.png" alt="dev-mailbox: every email sent in development, the one-time code one keystroke away" width="420"></picture></a><br><sub><b>dev-mailbox</b>: every email in development, codes one keystroke away</sub></td></tr>
<tr><td valign="top" width="50%"><a href="docs/screenshots/jobs-dashboard/errors-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/jobs-dashboard/errors-dark-desktop.png"><img src="docs/screenshots/jobs-dashboard/errors-light-desktop.png" alt="jobs-dashboard: failing jobs grouped by root cause" width="420"></picture></a><br><sub><b>jobs-dashboard</b>: failures grouped by root cause, retry in one click</sub></td><td valign="top" width="50%"><a href="docs/screenshots/auth-core/account-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/auth-core/account-dark-desktop.png"><img src="docs/screenshots/auth-core/account-light-desktop.png" alt="auth-core: the account security page with devices and recent activity" width="420"></picture></a><br><sub><b>auth-core</b>: the account security page</sub></td></tr>
</table>

<sub>Light or dark follows your GitHub theme. Click any image for full size; every screen, light and dark, desktop and mobile, is in <a href="docs/screenshots/"><code>docs/screenshots/</code></a>. All data is synthetic demo data.</sub>

## Samples

<table>
<tr><th>Sample</th><th>Screen</th><th>What you get</th><th>Depends on</th></tr>
<tr><td><a href="samples/mailer/"><b>mailer</b></a></td><td><a href="docs/screenshots/mailer/test-email-preview-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/mailer/test-email-preview-dark-desktop.png"><img src="docs/screenshots/mailer/test-email-preview-light-desktop.png" alt="mailer" width="200"></picture></a></td><td>Templated HTML + text email: SMTP in production, the dev mailbox in development, log and memory adapters, previews, header-injection checks</td><td>—</td></tr>
<tr><td><a href="samples/dev-mailbox/"><b>dev-mailbox</b></a></td><td><a href="docs/screenshots/dev-mailbox/inbox-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dev-mailbox/inbox-dark-desktop.png"><img src="docs/screenshots/dev-mailbox/inbox-light-desktop.png" alt="dev-mailbox" width="200"></picture></a></td><td><code>/dev/mailbox</code>: a live inbox with a sandboxed viewer, phone and dark previews, codes and links to copy, and checks that catch what Gmail will break. Development only</td><td>mailer</td></tr>
<tr><td><a href="samples/jobs/"><b>jobs</b></a></td><td><sub>no UI; see jobs-dashboard</sub></td><td>A job queue in your own database (no Redis): <code>SKIP LOCKED</code> on Postgres, retries with backoff, unique and scheduled jobs, cron, rate limits, batches. No UI of its own</td><td>—</td></tr>
<tr><td><a href="samples/jobs-dashboard/"><b>jobs-dashboard</b></a></td><td><a href="docs/screenshots/jobs-dashboard/overview-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/jobs-dashboard/overview-dark-desktop.png"><img src="docs/screenshots/jobs-dashboard/overview-light-desktop.png" alt="jobs-dashboard" width="200"></picture></a></td><td><code>/admin/jobs</code>: queues, states, live charts, job timelines, errors grouped by root cause, bulk retry and cancel. Admin only</td><td>jobs</td></tr>
<tr><td><a href="samples/webhooks/"><b>webhooks</b></a></td><td><sub>no UI</sub></td><td>Signed inbound webhooks: <code>POST /webhooks/{provider}</code> verifies the HMAC over the raw body (GitHub and Stripe schemes), refuses stale timestamps, stores each event once so a replay is a no-op, and does the work in a job. A provider without a secret answers 404, like one that doesn't exist</td><td>jobs</td></tr>
<tr><td><a href="samples/auth-core/"><b>auth-core</b></a></td><td><a href="docs/screenshots/auth-core/account-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/auth-core/account-dark-desktop.png"><img src="docs/screenshots/auth-core/account-light-desktop.png" alt="auth-core" width="200"></picture></a></td><td>Users, database sessions with rotation, the account security page, re-auth, email change, security emails, an audit trail, throttling</td><td>mailer, dev-mailbox</td></tr>
<tr><td><a href="samples/auth-password/"><b>auth-password</b></a></td><td><a href="docs/screenshots/auth-password/sign-up-strength-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/auth-password/sign-up-strength-dark-desktop.png"><img src="docs/screenshots/auth-password/sign-up-strength-light-desktop.png" alt="auth-password" width="200"></picture></a></td><td>Email + password: argon2id, verification, reset, progressive delays, no user enumeration, pre-hijacking defense</td><td>auth-core</td></tr>
<tr><td><a href="samples/auth-magic-link/"><b>auth-magic-link</b></a></td><td><a href="docs/screenshots/auth-magic-link/sent-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/auth-magic-link/sent-dark-desktop.png"><img src="docs/screenshots/auth-magic-link/sent-light-desktop.png" alt="auth-magic-link" width="200"></picture></a></td><td>Passwordless sign-in: a link and a 6-digit code in one email, single-use, hashed, short-lived, bound to the asking browser</td><td>auth-core</td></tr>
<tr><td><a href="samples/auth-totp/"><b>auth-totp</b></a></td><td><a href="docs/screenshots/auth-totp/enrol-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/auth-totp/enrol-dark-desktop.png"><img src="docs/screenshots/auth-totp/enrol-light-desktop.png" alt="auth-totp" width="200"></picture></a></td><td>Two-factor with an authenticator app: QR enrolment, recovery codes, trusted devices, replay protection, step-up</td><td>auth-core</td></tr>
<tr><td><a href="samples/realtime/"><b>realtime</b></a></td><td><a href="docs/screenshots/realtime/live-room-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/realtime/live-room-dark-desktop.png"><img src="docs/screenshots/realtime/live-room-light-desktop.png" alt="realtime" width="200"></picture></a></td><td>Channels over WebSocket with SSE and long-poll fallbacks, topic authorization on every join, presence, resume after reconnect</td><td>— (accounts with auth-core)</td></tr>
<tr><td><a href="samples/dev-dashboard/"><b>dev-dashboard</b></a></td><td><a href="docs/screenshots/dev-dashboard/insights-light-desktop.png"><picture><source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/dev-dashboard/insights-dark-desktop.png"><img src="docs/screenshots/dev-dashboard/insights-light-desktop.png" alt="dev-dashboard" width="200"></picture></a></td><td><code>/dev/dashboard</code>: live charts, traces, SQL with N+1 detection and EXPLAIN, logs, insights, routes explorer, ERD, migrations, tests, CI, a load lab and an optional AI assistant. Development only</td><td>—</td></tr>
</table>

Every sample's README opens with its key screens. All of them, light and dark, desktop and mobile, are in [`docs/screenshots/`](docs/screenshots/).

## Using a sample

From an agent: point it at the sample's folder in this repo (its `PROMPT.md` says what to do). Samples tools on the [rustoffrails.org MCP server](https://rustoffrails.org/mcp) (`list_samples`, `get_sample`, `diff_sample`) are coming soon; today that server serves the framework docs only.

By hand: each sample's `README.md` has the exact install procedure, and its `PROMPT.md` is a ready-to-paste prompt for your agent. In short:

1. Add the crates in `sample.toml` with `cargo add` (never with a version).
2. Copy `files/` into the app at the same paths.
3. Apply the wiring: each `[[wire]]` in `sample.toml` names a file, the spot (a `samples: <anchor>` comment in apps generated since 0.7.0, described in words in the README) and the exact code.
4. `cargo fmt --all`, then the Definition of Done.

Or mechanically, from a checkout of this repo:

```sh
tools/install.sh dev-mailbox path/to/app     # installs mailer first; refuses to overwrite a file (--force does)
```

## Repository

```
host/                 the blank app (generators/new.md, htmx) every sample installs into and is tested in
samples/<name>/       sample.toml, README.md, CHECKS.md, PROMPT.md, files/  (format: samples/FORMAT.md)
tools/install.sh      install a sample (and its dependencies) into an app
tools/install-test.sh regression checks for install.sh: dependency resolution, optional wiring (fixtures, no cargo)
tools/ci.sh           prove samples: fresh host copy, install, fmt, clippy, tests on SQLite and Postgres, offrails-check, cargo deny, cargo audit
tools/security-check.sh   every SECURITY marker and CHECKS.md row cites a test that exists
tools/demo.sh         a running demo with every sample and seed data (demo/, git-ignored)
tools/screenshots.sh  regenerate docs/screenshots/ from the demo with Playwright
tools/e2e.sh          a real browser through boosted links: every interactive page (auth, live room) works after a click, not only on a fresh load
tools/vendor-framework.sh   fetch the framework release (checksum-verified) into host/.offrails
```

Prove everything (needs a Postgres the suite may create databases in):

```sh
tools/vendor-framework.sh host
TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/postgres tools/ci.sh   # each sample alone, then all together
tools/security-check.sh
tools/e2e.sh                                                                          # Node >= 22.12, pnpm, Google Chrome
tools/demo.sh && open http://localhost:3900/dev/mailbox                              # tools/demo.sh stop
```

`host/` in development listens on 127.0.0.1 only and answers only local `Host` names (DNS rebinding can't reach `/dev`); `APP_BIND=0.0.0.0` opens it to a container's network and `APP_ALLOWED_HOSTS` adds a tunnel or LAN name. An unset `APP_ENV` means development and says so loudly at boot.

CI (`.github/workflows/ci.yml`) runs the same (`tools/e2e.sh` included), plus gitleaks over the whole history and an OWASP ZAP baseline against the demo app running in production mode (fresh random secrets, no `/dev`) with every sample installed.

## Versions

Samples are released with the framework: `version` in each `sample.toml` is the samples release it belongs to, and the repository is tagged per release (`v0.7.0`). `FRAMEWORK_VERSION` names the framework release `host/.offrails` is vendored from (checksum-verified); every sample is proven against it, `offrails-check` included.

## License

MIT or Apache-2.0, like the framework.
