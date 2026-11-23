#!/bin/sh
# Mechanical security gates over the samples (and host/), so a control can't lose its proof:
#
#   1. every `// SECURITY:` marker (or `{# SECURITY: … #}`, `/* SECURITY: … */`) names the test
#      that proves it: `(test: <name>)`;
#   2. every `(test: <name>)` in a marker names a test that exists;
#   3. every test a CHECKS.md table names (`` `test_name` `` in its Test column) exists.
#
#   tools/security-check.sh            exit 0 when all hold, 1 otherwise
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
errors=0
fail() { errors=$((errors + 1)); printf 'FAIL %s\n' "$1"; }

# Every Rust test (and test helper) name defined in the repo's code.
tests=$(grep -rhoE 'fn [a-z_][a-z0-9_]*' --include='*.rs' samples host/src host/tests 2>/dev/null \
  | sed 's/^fn //' | sort -u)
has_test() { printf '%s\n' "$tests" | grep -qx "$1"; }

# 1 + 2: markers. A marker may continue on the following comment lines.
markers=$(find samples host/src host/tests host/templates host/static -type f \
  \( -name '*.rs' -o -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.toml' -o -name '*.sh' \) 2>/dev/null \
  | sort | while IFS= read -r f; do
    awk -v f="$f" '
      function flush() { if (m != "") print f ":" at ": " m; m = "" }
      /SECURITY:/ { flush(); m = $0; at = FNR; next }
      m != "" && /^[[:space:]]*(\/\/|#|\{#|\*)/ && m !~ /\(test: / { m = m " " $0; next }
      { flush() }
      END { flush() }
    ' "$f"
  done)
count=0
if [ -n "$markers" ]; then
  while IFS= read -r line; do
    count=$((count + 1))
    where=$(printf '%s' "$line" | cut -d: -f1-2)
    # A marker may end with the file the test lives in: `(test: <name>, kernel_test.rs)`.
    names=$(printf '%s\n' "$line" \
      | grep -oE '\(test: [a-z_][a-z0-9_]*(, [a-z_][a-z0-9_]*)*(, [a-z_][a-z0-9_/]*\.rs)?\)' \
      | sed 's/^(test: //; s/)$//; s/, [a-z_][a-z0-9_/]*\.rs$//' | tr ',' '\n' | tr -d ' ' || true)
    if [ -z "$names" ]; then
      fail "$where: SECURITY marker names no test; add (test: <name>)"
      continue
    fi
    for n in $names; do
      has_test "$n" || fail "$where: SECURITY marker cites test \`$n\`, which doesn't exist"
    done
  done <<EOF
$markers
EOF
fi

# INVARIANT markers cite tests too.
invariants=$(grep -rnoE --exclude='*.md' 'INVARIANT:.*\(test: [a-z_][a-z0-9_]*\)' samples host/src 2>/dev/null || true)
if [ -n "$invariants" ]; then
  while IFS= read -r line; do
    n=$(printf '%s\n' "$line" | sed -E 's/.*\(test: ([a-z_][a-z0-9_]*)\).*/\1/')
    has_test "$n" || fail "${line%%:*}: INVARIANT cites test \`$n\`, which doesn't exist"
  done <<EOF
$invariants
EOF
fi

# 3: CHECKS.md tables.
checked=0
for checks in samples/*/CHECKS.md; do
  [ -f "$checks" ] || continue
  # The Test column is the last cell of each table row; names in backticks there are tests.
  # shellcheck disable=SC2016 # literal backticks
  for n in $(grep -E '^\|' "$checks" | grep -vE '^\|[[:space:]]*-' | awk -F'|' '{ print $(NF - 1) }' \
    | grep -oE '`[a-z][a-z0-9_]*`' | tr -d '`' | grep -v '^test$' | sort -u); do
    checked=$((checked + 1))
    has_test "$n" || fail "$checks names test \`$n\`, which doesn't exist"
  done
done

printf 'security-check: %s SECURITY markers, %s CHECKS.md test names, %s error(s)\n' "$count" "$checked" "$errors"
[ "$errors" = 0 ]
