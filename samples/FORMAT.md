# The sample format

A sample is tested reference code an agent copies into a Rust off Rails app. Once copied, the app owns it. This file is the contract every sample follows, so an agent (by hand) and `tools/install.sh` (mechanically) install any sample the same way.

## Folder

```
samples/<name>/
  sample.toml     what to add (crates), where to wire it (anchors), what it depends on
  README.md       what it is, the install procedure for an agent, wiring, adapting, screenshots
  CHECKS.md       what "working and safe" means: threat model, invariants, and the test for each
  PROMPT.md       a ready-to-paste prompt that installs and proves it
  files/          the code, at the app paths it lands on (src/, templates/, static/, migration/, tests/)
```

- `<name>` is kebab-case (`dev-mailbox`, `auth-password`).
- **Every file under `files/` is copied to the same path in the app.** There is no file list to keep in sync. A sample never ships a file that `host/` already has; it changes shared files only through wiring.
- Files are written against `host/` exactly as they will look in an app: formatted with `cargo fmt`, clippy-clean, and using the host crate name `offrails_host` where a crate path is needed (tests: `use offrails_host::…`). `install.sh` replaces `offrails_host` with the app's package name; an agent installing by hand does the same.
- Migrations ship as files with a fixed timestamped name (`m20261016_000100_create_mailbox_messages.rs`), registered through wiring. Never edit a shipped migration; a change is a new migration.
- Tests live in `files/tests/app/<sample>_test.rs` (one module in the app's single test binary) and run on SQLite and Postgres.

## `sample.toml`

A strict subset of TOML so a POSIX shell can read it: top-level `key = "value"` lines, two arrays, then `[[wire]]` tables whose `text` is a `'''` literal block (the opening `'''` ends its line; the closing `'''` stands alone).

```toml
name = "dev-mailbox"
version = "0.7.0"                 # the samples release it belongs to
summary = "One line: what it adds."
depends_on = ["mailer"]           # other samples, installed first (recursively)
extracted_from = "Rust off Rails apps"

# `cargo add` arguments, one per line, never with a version: cargo picks it, Cargo.lock records it.
crates = [
  "lettre --no-default-features --features builder,smtp-transport,pool,hostname,tokio1-rustls-tls",
]

[[wire]]
file = "src/kernel/mod.rs"        # an app path
anchor = "kernel mods"            # the line in that file containing `samples: kernel mods`
text = '''
pub mod mailbox_web;
'''
```

| Key | Required | Meaning |
|-----|----------|---------|
| `name` | yes | The folder name |
| `version` | yes | The samples release it belongs to (proven against the framework in `FRAMEWORK_VERSION`) |
| `summary` | yes | One line, shown in listings (and in the planned samples MCP tools) |
| `depends_on` | yes (may be `[]`) | Samples this one needs, installed first |
| `extracted_from` | yes | Where the code came from, in public words ("Rust off Rails apps") |
| `crates` | yes (may be `[]`) | `cargo add` argument lines |
| `[[wire]]` | no | One insertion into a shared file each (`file`, `anchor`, `text`, optional `when`) |

### Wiring

Shared files (`routes.rs`, `kernel/mod.rs`, `config.rs`, `state.rs`, `migration/src/lib.rs`, `tests/app/main.rs`, layouts, `.env.example`, …) carry one-line anchor comments where samples insert code:

```rust
    // samples: config fields
```
```html
{# samples: nav links #}
```
```sh
# samples: env
```

A `[[wire]]` puts its `text` on the lines **above** the anchor line, indented like the anchor, so the anchor stays for the next sample. Rules for `text`:

- It is complete, compilable code for that spot (a field, a `mod` line, a match arm, a route), written at indentation zero; `install.sh` indents it.
- It is idempotent: when all its lines already appear together in the file, nothing is inserted.
- It is self-contained: use full paths (`crate::kernel::mailer::Mailer`) rather than adding `use` lines elsewhere.
- Run `cargo fmt --all` after installing (the Definition of Done does): `rustfmt` sorts `mod` lines and may rewrap.

#### Optional wiring (`when`)

A sample that works alone but adapts to another one, without depending on it, marks those wires `when = "<other sample>"`:

```toml
[[wire]]
file = "src/channels/identity.rs"
anchor = "identity source"
when = "auth-core"               # applied only when auth-core is installed too
text = '''
pub use crate::channels::accounts::{DEV_GUESTS, by_session, current, session_live};
'''
```

- `install.sh` applies it when `<other>` is already installed, or later, when installing `<other>` (it then applies every waiting wire of the samples already in the app). Without `<other>` it prints `wait … (applies when <other> is installed)` and changes nothing.
- Code that only compiles with `<other>` ships as a normal file that **no module declares** (`src/channels/accounts.rs`); an optional wire declares it (`pub mod accounts;`). Without `<other>` the file is copied but not built.
- To switch behavior without editing code, the sample re-exports its default with a glob under the anchor (`pub use guests::*;`) and the optional wire adds an explicit `pub use` above it: explicit names win over a glob, so the default stays compiled but unused.
- By hand: README "Wiring" lists the optional wires under "With <other> installed".
- `ci.sh all` proves the combination; each sample alone proves it without.

The anchors `host/` provides (each file says what goes there):

| File | Anchors |
|------|---------|
| `src/lib.rs` | `lib mods` |
| `src/kernel/mod.rs` | `kernel mods` |
| `src/kernel/ui.rs` | `kernel tabs` (a `Tab { … }` in the kernel header), `hidden tabs` (the key of a host tab a sample replaces, e.g. `"system"`) |
| `src/kernel/introspect.rs` | `introspect sections` (`out["x"] = …;`) |
| `src/kernel/redact.rs` | `token routes` (a route pattern whose `{token}` segment is a secret, e.g. `"/login_links/{token}",`: logs show it as `[redacted]`) |
| `src/config.rs` | `config fields`, `config debug`, `config parse`, `config init`, `config test`, `config sections` (a sample's own config struct, appended) |
| `src/state.rs` | `state fields`, `state build`, `state init`, `state fns` |
| `src/routes.rs` | `routes` (`app = app.route(…)`), `dev routers` (merged in development only), `outer layers` (a `.layer(…)` outside everything but the request id: it sees every request, panics and timeouts included), `paths`, `routes table` (`ROUTES` rows) |
| `src/controllers/mod.rs` | `controller mods` |
| `src/controllers/application.rs` | `ctx init`, `extractors` |
| `src/kernel/security.rs` | `dev csp` (a CSP directive added in development only, e.g. `"report-uri /dev/csp-reports"`) |
| `src/controllers/dev.rs` | `dev routes`, `dev tiles` (a `Tile { … },`), `dev try-it` (a `TryIt { … },`), `system facts` (`facts.push(…);`) |
| `src/controllers/meta.rs` | `sitemap paths` |
| `src/views/mod.rs` | `view mods`, `ctx fields` |
| `src/models/mod.rs` | `model mods`, `model aliases` |
| `src/tasks/mod.rs` | `task mods`, `tasks` |
| `src/main.rs` | `cli commands`, `cli dispatch`, `serve start`, `serve stop`, `tracing layers` (a `Box::new(…)` layer beside the log formatter) |
| `migration/src/lib.rs` | `migration mods`, `migrations` |
| `templates/layouts/application.html` | `app head` (a `<script>` or `<link>` app pages need, loaded on every page: see [Scripts on app pages](#scripts-on-app-pages)), `dev footer links` |
| `templates/kernel/layout.html` | `kernel head` (a `<link>` or `<script>` every kernel page loads, usually inside an `{% if %}`), `kernel main` (markup at the top of every kernel page's `<main>`, e.g. the dev dashboard's Ask AI bar); `chrome` is in scope, `chrome.theme.return_to` is the page's path and query |
| `templates/shared/_nav.html` | `nav links` |
| `tests/app/main.rs` | `test mods` |
| `tests/app/support.rs` | `test support` (methods on `TestApp`) |
| `tests/app/factories.rs` | `factories` |
| `tests/app/security_test.rs` | `router sources` (files that mount routes, for the ROUTES check) |
| `tests/app/kernel_web_test.rs` | `no-store paths` |
| `tests/app/theme_switch_test.rs` | `kernel pages` (every full page a sample renders in the kernel layout) |
| `.env.example` | `env` |
| `compose.yaml` | `compose env` |

Samples that own a shared file add anchors of their own for the samples that depend on them:

| File | Sample | Anchors |
|------|--------|---------|
| `src/mailers/mod.rs` | mailer | `mailer mods` (`pub mod <name>_mailer;`) |
| `src/mailers/previews.rs` | mailer | `previews` (a `Preview { … },` in `PREVIEWS`) |
| `src/models/auth_event.rs` | auth-core | `auth events` (in `auth_event::record`, before the row is written: every audit event, with `kind`, `user_id` and `meta` in scope) |
| `src/controllers/auth.rs` | auth-core | `sessions ended` (in `auth::sessions_ended(state, user_id)`, called after every commit that ends sessions); the auth samples' other anchors are listed in their READMEs |
| `src/jobs/mod.rs` | jobs | `worker mods` (`pub mod <name>;`), `worker dispatch` (an arm of `dispatch`), `worker config` (an arm of `worker_config`), `worker names` (a name in `WORKERS`): a sample that ships a worker registers it here |
| `src/jobs/recurring.rs` | jobs | `recurring` (a `Recurring { ... },` in `SCHEDULE`, its `job` written with full paths: `crate::jobs::Worker::into_job(...)`) |
| `src/channels/mod.rs` | realtime | `channel mods` |
| `src/channels/identity.rs` | realtime | `identity source` (an explicit `pub use` of another people source, above the guests' glob) |

An app made by `generators/new.md` before 0.7.0 has no anchors. Then `install.sh` refuses and names each missing anchor; the agent applies that wiring by hand at the spot the anchor table describes (README "Wiring" says it in words for every insertion).

## Comments that guide the next model

Samples are read and adapted by models of every size. These markers tell a model what it may change, what it must keep, and why. A weak model that changes **only** `// APP:` lines still gets a correct app.

| Marker | Means | Example |
|--------|-------|---------|
| `// APP: …` | This line or block is meant to be customized, and how (names, copy, limits, routes) | `const KEEP: u64 = 500; // APP: how many messages development keeps` |
| `// WHY: …` | A non-obvious choice, in one line, so nobody "simplifies" it away | `// WHY: BEGIN IMMEDIATE, or a read-then-write transaction fails with "database is locked"` |
| `// INVARIANT: … (test: <test_name>)` | Must stay true; the named test guards it | `// INVARIANT: development always delivers to the mailbox (test: development_always_uses_the_dev_mailbox)` |
| `// SECURITY: … (test: <test_name>)` | A security-relevant line: the attack it prevents, what breaks if it goes, and the test that proves it (may continue on the next comment lines) | `// SECURITY: no allow-scripts, no allow-same-origin: mail can't run code or read this page (test: the_html_body_is_served_alone_in_a_sandbox)` |
| `// GUIDE: .offrails/guides/<guide>.md#<anchor>` | The framework section this code implements (the app's vendored copy) | `// GUIDE: .offrails/guides/mailers.md#the-dev-mailbox` |

- In templates use `{# APP: … #}` (Askama), in CSS `/* APP: … */`, in shell and TOML `# APP: …`.
- Dense where it matters, absent where the code is obvious. Never narrate what the next line does.
- Every `// SECURITY:` marker ends with `(test: <name>)`, and every `(test: <name>)` (in SECURITY and INVARIANT markers, and every test named in a CHECKS.md table) names a test that exists. `tools/security-check.sh` fails otherwise.
- READMEs link guides by their public URL too: `https://rustoffrails.org/docs/guides/<guide>` (e.g. `https://rustoffrails.org/docs/guides/mailers`).

## Theming

Kernel pages (and the app layout and error pages) have one theme: System, Light or Dark, chosen with the switch in the kernel header. A sample with UI follows it; it never adds a theme mechanism of its own.

- **The choice is a cookie:** `offrails_theme=system|light|dark` (`Path=/`, `SameSite=Lax`, a year, not HttpOnly; `src/kernel/theme.rs`). An unknown value means System.
- **The server renders it:** `<html data-theme="…">` and `<meta name="color-scheme">` on every page, so the first paint is right with no inline script (the CSP forbids those). A kernel handler takes the `ThemeSwitch` extractor and passes it to `Chrome::new`; the layout does the rest. A page that answers a POST (a confirmation) sets `return_to` to a GET page.
- **Without JS** the switch is a `POST /theme` form (CSRF-checked like every POST, `return_to` same-site only). **With JS** (`static/kernel/admin.js`) it switches instantly, writes the same cookie and dispatches `themechange` on `document`, with `detail = { theme, scheme }` (`scheme` is what shows now, `light` or `dark`). It fires again when the OS flips while the choice is System.
- **CSS:** each color token is defined **once**, with `light-dark(<light>, <dark>)`, on `:root` in the sample's own stylesheet; `admin.css` sets `color-scheme` (`light dark`, or `light` / `dark` under `:root[data-theme]`), which picks the side. Never write a `@media (prefers-color-scheme: dark)` color block: it ignores the switch. Shadows take `light-dark()` in their color. An element that pins its own `color-scheme` (an email preview frame) resolves `light-dark()` by that scheme, so give it fixed colors.
- **JS that reads colors** (`getComputedStyle`, a canvas chart) re-reads them in a `themechange` listener. SVG styled by CSS classes needs nothing.
- **Brand tones** are the `/* APP: */` token blocks: the shared ones at the top of `static/kernel/admin.css` (`--accent`, `--panel`, …), a sample's own at the top of its stylesheet (`--mbx-*` in `mailbox.css`, `--st-*` and `--chart-*` in `jobs.css`). Change both sides of each `light-dark()` and keep WCAG 2.2 AA in both (axe with the OS light and dark, and with the switch forcing each).
- **Tests:** add the sample's page paths at `samples: kernel pages` (`every_kernel_page_renders_data_theme` checks each renders `data-theme` and the switch), and assert its stylesheet has no `prefers-color-scheme` block.
- **App pages (Tailwind `dark:`)** follow the same switch. `templates/layouts/application.html` renders `data-theme` from the cookie (`ctx.theme`), and `assets/app.css` defines the one `dark` variant (Tailwind 4, verified with 4.3.3; `.offrails/guides/views.md#dark-mode`):
  ```css
  @custom-variant dark {
    &:where([data-theme=dark], [data-theme=dark] *) { @slot; }
    @media (prefers-color-scheme: dark) {
      &:where(:root:not([data-theme=light]), :root:not([data-theme=light]) *) { @slot; }
    }
  }
  ```
  `data-theme=dark` forces dark, `light` forces light, `system` follows the OS. A sample's app pages just use `dark:` classes; `tailwind_dark_utilities_follow_the_theme_switch` checks the built CSS carries both selectors.

## Scripts on app pages

The app layout boosts every link and form (`<body hx-boost="true">`): a click fetches the next page and swaps `<body>`, and nothing in the new page's `<head>` runs. A script a page adds in `{% block head %}` works on a direct load and is dead after a boosted click, so a sample never does that:

- **Load it once, from the layout:** wire the `<script src="…" defer>` at `samples: app head`, with a digested URL from a ctx field (`ctx fields`: `pub auth_js: String`; `ctx init`: `auth_js: state.assets.path("auth.js"),`). It then loads on every app page, so keep it small and inert where its markup is absent.
- **Delegate, don't bind:** one `document` listener per behavior, keyed by a data attribute (`e.target.closest("[data-reveal]")`), works for the first page, every boosted page and every htmx swap with no re-binding.
- **Set up elements on `htmx:load`** (it fires for the first page and for each swapped fragment, with the new element as `e.detail.elt`) when something must be initialized, and mark what's done (`data-started`) so nothing binds twice. Tear down on `htmx:beforeSwap` what outlives the page (a socket topic, a timer).
- **Guard the file** (`if (window.offrailsAuth) return;` in an IIFE): it may still be loaded twice in an app that has an older page.
- **Prove it in a browser:** `tools/e2e.sh` arrives at each interactive page through a boosted link and checks the behavior (a direct `page.goto` would hide this bug).

Kernel pages render in `templates/kernel/layout.html`, which doesn't boost: their scripts load per page (`Chrome::script`), and links into them from app pages carry `hx-boost="false"` (a boosted swap would keep the app layout's `<head>`).

## README.md

Sections, in this order:

1. **Title and one paragraph**: what it is, what it replaces (Rails/Phoenix), what it depends on, "extracted from Rust off Rails apps".
2. **Screens**: the key screens inline as `<picture>` elements (dark source under `prefers-color-scheme: dark`, light `<img>` with a `width`, each linking to the full image), then a table linking every screenshot (`docs/screenshots/<sample>/`).
3. **Install**: by hand: the exact numbered procedure (crates, copy `files/`, each wiring step in words with its file, then `cargo fmt`, `cargo run -- routes`, the Definition of Done). `tools/install.sh <sample> <app>` is the mechanical version.
4. **After installing**: what the agent must still do in the app (env vars in the deploy config, `docs/decisions.md`, the `AGENTS.md` header line).
5. **Adapting it**: 3 to 6 common variations as short recipes (e.g. "add an SMTP provider", "show the mailbox in production behind admin access"), each naming the `// APP:` lines it touches.
6. **Do not change**: the invariants, each with the test that guards it.
7. **How it works**: the design in a few paragraphs, with the routes table and the guide links (`.offrails/guides/…` and `https://rustoffrails.org/docs/guides/…`).
8. **Files**: one line per file.

## PROMPT.md

A ready-to-paste prompt for an agent working in an app: "Install the `<sample>` sample into this app, following its README.md …", what to adapt and what to leave alone, and it ends with the exact commands that prove it works (the Definition of Done plus the sample's own checks).

## CHECKS.md

What "working and safe" means, each item with the test (or command) that proves it:

- **Threat model**: a STRIDE table (`| STRIDE | Threat | Control | Test |`) for anything reachable over HTTP; `n/a: <why>` where a category can't apply. The Test cell names tests in backticks (`` `test_name` ``); `tools/security-check.sh` fails when one doesn't exist.
- **Invariants**: behavior that must hold (e.g. "development always delivers to the dev mailbox").
- **Commands**: how to run them (`tools/ci.sh <sample>`).

## Proving a sample

```sh
TEST_DATABASE_URL=postgres://… tools/ci.sh <sample>   # alone
TEST_DATABASE_URL=postgres://… tools/ci.sh all        # together with every other sample
```

`ci.sh` copies `host/` to `.cache/ci/<name>/app`, installs with `install.sh`, then runs `cargo fmt` (and fails when a shipped file changes: ship formatted code; a shipped file another installed sample wires into is checked as shipped, by rustfmt on that file alone), builds the CSS, regenerates `docs/routes.md`, `clippy -D warnings` (plus the framework's `unwrap_used`/`expect_used` gate on non-test code), the test suite on SQLite and on Postgres, `offrails-check`, `cargo deny`, `cargo audit` and `fmt --check`. Repo-wide security gates (`tools/security-check.sh`, gitleaks over the history, the ZAP baseline against the demo with every sample) run in `.github/workflows/ci.yml`. Never weaken a gate to get green.

## host/ is frozen

Samples never edit `host/`. A change to it (a new anchor, a fix) is its own commit titled `host: …`, because every sample is proven against it.
