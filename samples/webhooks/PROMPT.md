# Prompt: install the webhooks sample

Paste this to the agent working in your Rust off Rails app:

---

Install the **webhooks** sample (signed inbound webhooks) from the Rust off Rails samples (the `samples/webhooks/` folder of github.com/rust-off-rails/samples) into this app. It depends on the **jobs** sample; install that first if `docs/decisions.md` doesn't list it.

1. Read `samples/webhooks/README.md` and `CHECKS.md` first, and the CSRF section of `.offrails/guides/security.md`.
2. If this repo has `tools/install.sh`, run `tools/install.sh webhooks .`. Otherwise follow the README's "Install" steps by hand: `cargo add hmac` and `cargo add constant_time_eq` (no versions), copy `files/` keeping paths (replace `offrails_host` with this crate's name), then each wiring step at its `samples: <anchor>` comment, including the four worker anchors in `src/jobs/mod.rs` (add them by hand if the app's jobs sample predates them).
3. Change only lines marked `// APP:`: replace the example arms in `handle` (`src/jobs/process_webhook.rs`) with this app's reactions to the events it subscribes to (idempotent on `delivery.event_id`), and adjust the limits in the README's "Adapting it" if the app needs it. Keep every `// SECURITY:`, `// INVARIANT:` and `// WHY:` line and the code under it. Leave the CSRF layer as it is (provider servers pass it: README, "CSRF"), do not parse the body before `Provider::verify`, do not compare signatures with `==`, and do not put the payload or a secret in job args.
4. Add `APP_WEBHOOK_GITHUB_SECRET` and/or `APP_WEBHOOK_STRIPE_SECRET` to the deploy configuration (never to the repo) for the providers this app uses, and tell the human to paste the same secret into the provider's dashboard and to point it at `https://<app>/webhooks/<provider>`. A provider without a secret has no route. Make sure a worker runs the `default` queue (it also runs the daily `prune_webhook_events` retention job; set `KEEP_DAYS` to the app's retention policy). Log the install and the enabled providers in `docs/decisions.md`.
5. Prove it, and paste the output:

```sh
cargo fmt --all && cargo run -q -- db migrate && cargo run -q -- routes
sh .offrails/tools/offrails-check
cargo clippy --all-targets -- -D warnings
cargo clippy --lib --bins -- -D clippy::unwrap_used -D clippy::expect_used
cargo nextest run webhook
cargo nextest run
TEST_DATABASE_URL=postgres://postgres:postgres@localhost:5432/postgres cargo nextest run
cargo run -q -- db rollback --steps 1 && cargo run -q -- db migrate
```

Then run the app (`bin/dev`, with a secret in `.env`) and send a signed test delivery with the `curl` and `openssl` commands from the README: it answers `{"status":"received"}`, the same delivery again `{"status":"duplicate"}`, a changed body 401, and `cargo run -q -- jobs list` shows the `process_webhook` job done.

Report what you installed, which providers you enabled, which events `handle` acts on (and which `// APP:` lines you changed), and the results.
