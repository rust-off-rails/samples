## What changes

<!-- What was wrong or missing, and what this does about it. Link the issue: "Fixes #123". -->

## How you know it works

<!-- The commands you ran and what you saw: `tools/ci.sh <sample>` (SQLite and Postgres), and `tools/ci.sh all` if wiring or a shared file changed. For a doc fix: what you built from the corrected docs, with which agent, and the crate versions it was verified against. Say what you couldn't check. "Tests pass" alone isn't enough. -->

- [ ] `CHECKS.md` updated if a threat, invariant or test changed (`tools/security-check.sh` passes)
- [ ] Part changes the framework also ships (`template/parts/`) noted, so the next sync carries them
- [ ] No security rule weakened (or: why, and how it was reviewed)
