---
name: gogcli
description: CLI for Gmail, Calendar, Drive, Contacts, Tasks, Sheets.
compatibility: Requires gog CLI (github.com/openclaw/gogcli).
title: /gogcli
parent: Skills
permalink: /skills/gogcli/
nav_order: 15
---

# gogcli

CLI for Google Workspace via [openclaw/gogcli](https://github.com/openclaw/gogcli).

## Account Configuration

The `gog` CLI holds one account per mailbox: Qraft, personal, and one per company with its own Google organization. There is no default: every command names its own with `-a <alias>`, at the end of the command so that permission rules, which match its start, still apply.

The aliases and their addresses are in `private/accounts.md` next to this file, never published.

**Always use `gog` for email, the personal account included** — never the Gmail MCP connector (`mcp__claude_ai_Gmail__*`).

## On orca-host

The binary is in the image, from the release archive, checksum-verified: see the `Dockerfile` at the root of this repository. There is no OS keychain there, so tokens go to gog's encrypted file keyring, under `~/.local/share/gogcli` on the data disk. Its password comes from the session environment, a line of `config/env.tpl`:

```
GOG_KEYRING_PASSWORD={{ op://AI Agents/gog_keyring/password }}
```

The clients come from the laptop, once: gog keeps them in `~/Library/Application Support/gogcli/credentials-<client>.json`. Each file goes into the `AI Agents` vault as a Document named `gog_oauth_client_<client>`, as is: drag it into the 1Password app.

Then once per host, from an Orca terminal:

```bash
~/.claude/skills/gogcli/setup-host.sh
```

It switches gog to the file keyring, stores each account's OAuth client (one per Google organization) from the 1Password document `gog_oauth_client_<client>`, then asks one browser consent per account and sets the aliases: `--manual` prints a URL, open it on the laptop, paste back the URL the browser lands on. A rerun only does what is missing. The clients and the tokens are on the data disk: they survive a restart, a redeploy and a rebuild.

`Google API error (403 accessNotConfigured)` on one account: the API is off in that client's Google Cloud project, whose number the error gives. Enable it with the account that owns the project, from the laptop: `gcloud services enable calendar-json.googleapis.com --project <number>` (`gmail.googleapis.com`, `drive.googleapis.com` for the others).

## A new account

Each account has its own OAuth client, in a Google Cloud project of its own organization: the client of one organization is never reused for another.

The projects, with their numbers and IDs, are listed in `private/accounts.md`.

A project ID cannot be changed. From the new account, in the Google Cloud console:

1. A project in the account's organization, `Google CLI - nicolasrouanne`, ID `gogcli-nr-<client>`.
2. APIs: Gmail, Google Calendar, Google Drive, Google Docs, Google Sheets.
3. Google Auth Platform: Audience **Internal** for a Workspace organization. A gmail.com account can only be External: publish the app (In production), since an app left in Testing loses its tokens after 7 days.
4. Clients → Create client → **Desktop app**, download the JSON.
5. Drag it into the `AI Agents` vault as a Document named `gog_oauth_client_<client>`.
6. A row in the Aliases table of `private/accounts.md`, then rerun `setup-host.sh`: it only does the new account.

## Examples

The accounts are authorized for all of gog's user services, its default `--services user`. A service whose API is off in the project answers `403 accessNotConfigured`: see above.

```bash
gog gmail search 'newer_than:7d from:x@example.com' -a qraft
gog gmail thread <threadId> -a qraft
gog gmail send --to x@example.com --subject "Hi" --body "Text" -a qraft

gog calendar events primary --from 2025-01-15T00:00:00Z --to 2025-01-16T00:00:00Z -a qraft
gog calendar create primary --summary "Meeting" --from <RFC3339> --to <RFC3339> -a qraft

gog drive search "quarterly report" -a qraft
gog drive upload ./file.pdf --parent <folderId> -a qraft
gog drive download <fileId> --out ./file.pdf -a qraft
```

Use `--json` for parseable output, `--help` on any command for options.
