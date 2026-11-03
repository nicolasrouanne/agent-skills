#!/usr/bin/env bash
# gog on an orca-host, once per host: the file keyring, each account's OAuth client from 1Password, one browser
# consent per account, its alias (no default account: every command names its own). A rerun only does what is
# missing: a client already stored, an account already authorized, are skipped. No --services: gog's default,
# all its user services, as qraft has.
# Needs GOG_KEYRING_PASSWORD in the session (env.tpl) and, per client, the 1Password document
# gog_oauth_client_<client>: the laptop's credentials-<client>.json as is. For each account,
# `--manual` prints a URL: open it on the laptop, accept, paste back the URL the browser lands on.
set -euo pipefail
: "${GOG_KEYRING_PASSWORD:?missing: add it to env.tpl, then make restart}"

gog auth keyring file >/dev/null
clients=$(gog auth credentials list -p 2>/dev/null | tail -n +2 | cut -f1)
authorized=$(gog auth list -j | jq -r '.accounts[].email')
while read -r alias email client <&3; do
  grep -qxF "$client" <<< "$clients" \
    || op document get "gog_oauth_client_$client" --vault "${OP_VAULT:-AI Agents}" \
       | jq 'if .installed then . else {installed: .} end' \
       | gog auth credentials set - --client "$client" >/dev/null
  grep -qxF "$email" <<< "$authorized" \
    || gog auth add "$email" --client "$client" --manual
  gog auth alias set "$alias" "$email" >/dev/null
done 3<<'ACCOUNTS'
qraft    nicolas.rouanne@qraft.tech  qraft
billi    nicolas.rouanne@billi.so    billi
perso    nico.rouanne@gmail.com      perso
gybe     nicolas.rouanne@gybe.io     gybe
jacanda  nicolas.rouanne@jacanda.ai  jacanda
ACCOUNTS

gog auth list
