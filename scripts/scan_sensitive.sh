#!/usr/bin/env bash
# Scan files for sensitive terms before publishing to this public repo.
#
# The term list lives OUTSIDE this repo (private vault) so the denylist
# itself doesn't leak. Override with SENSITIVE_TERMS_FILE.
#
# Usage:
#   scripts/scan_sensitive.sh [file...]    # scan given files
#   scripts/scan_sensitive.sh              # scan all git-tracked files
#
# Exits 1 if any term is found (with file:line context), 0 otherwise.
set -euo pipefail

TERMS_FILE="${SENSITIVE_TERMS_FILE:-$HOME/work/vault/tools/sensitive-terms.txt}"

if [[ ! -f "$TERMS_FILE" ]]; then
  echo "error: terms file not found: $TERMS_FILE" >&2
  echo "set SENSITIVE_TERMS_FILE or create the file in the vault." >&2
  exit 2
fi

# Strip comments and blank lines from the term list.
PATTERNS=$(mktemp)
trap 'rm -f "$PATTERNS"' EXIT
grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$TERMS_FILE" > "$PATTERNS" || {
  echo "error: no terms in $TERMS_FILE" >&2
  exit 2
}

if [[ $# -gt 0 ]]; then
  MATCHES=$(grep -n -i -F -f "$PATTERNS" "$@" 2>/dev/null || true)
else
  MATCHES=$(git ls-files -z | xargs -0 grep -n -i -F -f "$PATTERNS" 2>/dev/null || true)
fi

if [[ -n "$MATCHES" ]]; then
  echo "$MATCHES"
  echo >&2
  echo "✗ sensitive terms found — do not publish (see matches above)" >&2
  exit 1
fi
echo "✓ clean ($(wc -l < "$PATTERNS" | tr -d ' ') terms checked)"
