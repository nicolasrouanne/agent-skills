#!/usr/bin/env bash
# gog on an orca-host, once per host: the file keyring, each account's OAuth client from 1Password, one browser
# consent per account, its alias (no default account: every command names its own). A rerun only does what is
# missing: a client already stored, an account already authorized, are skipped. No --services: gog's default,
# all its user services, as qraft has.
# Needs GOG_KEYRING_PASSWORD in the session (env.tpl) and, per client, the 1Password document
# gog_oauth_client_<client>: the laptop's credentials-<client>.json as is. For each account,
# `--manual` prints a URL: open it on the laptop, accept, paste back the URL the browser lands on.
# The accounts come from the Aliases table of private/accounts.md, never published; the client is named after the alias.
set -euo pipefail
: "${GOG_KEYRING_PASSWORD:?missing: add it to env.tpl, then make restart}"

# The Aliases table of private/accounts.md, as "alias address" lines: every row with an address must parse,
# and there must be some, or this stops here rather than silently skipping an account.
accounts() {
  local rows parsed
  rows=$(grep -E '^\|.*@' "$(dirname "$0")/private/accounts.md")
  parsed=$(sed -nE 's/^\|[[:space:]]*`?([A-Za-z0-9-]+)`?[[:space:]]*\|[[:space:]]*([^[:space:]|]+@[^[:space:]|]+)[[:space:]]*\|.*/\1 \2/p' <<< "$rows")
  [[ -n "$parsed" && $(wc -l <<< "$rows") -eq $(wc -l <<< "$parsed") ]] \
    || { echo "private/accounts.md: expected rows '| \`alias\` | address |', got:" >&2; echo "$rows" >&2; exit 1; }
  echo "$parsed"
}

gog auth keyring file >/dev/null
clients=$(gog auth credentials list -p 2>/dev/null | tail -n +2 | cut -f1)
authorized=$(gog auth list -j | jq -r '.accounts[].email')
while read -r alias email <&3; do
  client=$alias
  grep -qxF "$client" <<< "$clients" \
    || op document get "gog_oauth_client_$client" --vault "${OP_VAULT:-AI Agents}" \
       | jq 'if .installed then . else {installed: .} end' \
       | gog auth credentials set - --client "$client" >/dev/null
  grep -qxF "$email" <<< "$authorized" \
    || gog auth add "$email" --client "$client" --manual
  gog auth alias set "$alias" "$email" >/dev/null
done 3< <(accounts)

gog auth list
