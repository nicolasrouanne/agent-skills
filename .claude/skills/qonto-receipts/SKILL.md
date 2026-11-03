---
name: qonto-receipts
description: "Audit missing receipts (justificatifs) on Qonto transactions for any org (gybe, qraft), excluding lost/not-required ones. Then hunt recoverable invoices by email/portal and attach them to the right transaction."
title: /qonto-receipts
parent: Skills
permalink: /skills/qonto-receipts/
nav_order: 36
---

# Qonto Receipts — missing-receipt audit & recovery

Find every settled debit transaction with no attached receipt, ignore the ones Nicolas already declared **lost** or **not required** in Qonto, then help recover and attach what can still be recovered.

## Orgs & credentials

| Org slug | 1Password item (vault `AI Agents`) | Env vars (preferred, in `~/.zshrc`) |
|---|---|---|
| `gybe` | `chezmoi_qonto_gybe` | `QONTO_GYBE_ORGANIZATION_ID` / `QONTO_GYBE_API_KEY` |
| `qraft` | `chezmoi_qonto_qraft` | `QONTO_QRAFT_ORGANIZATION_ID` / `QONTO_QRAFT_API_KEY` |

Bank accounts are discovered dynamically from `GET /v2/organization` — never hardcode account IDs or IBANs in the repo.

## Step 1 — Audit

```bash
uv run python missing_receipts.py --org gybe [--since YYYY-MM-DD] [--min-amount N] [--json out.json]
```

(`missing_receipts.py` lives in this skill's folder.) It paginates all transactions of every active account and keeps only: `side=debit`, `status=completed`, empty `attachment_ids`, **not** `attachment_lost`, and `attachment_required=true`. Output: table grouped by month (amount-sorted, with transaction IDs) + summary with excluded counts on stderr.

API notes (hard-won):
- Qonto's WAF returns **403 for the default Python-urllib User-Agent** — the script sends a curl UA.
- Some transaction labels contain raw control characters → `json.loads(..., strict=False)` (raw `jq` on the response can fail).
- Paginate with `meta.next_page`; verify the scanned count looks complete before drawing conclusions.

## Step 2 — Triage the results

Classify each line before hunting anything:

1. **Recoverable online** — subscriptions & platforms that email or host their invoices: Apple, Google (Cloud/Workspace/One), Spotify, Railway, Starlink, Uber, Trainline, Ryanair, Expedia, Booking/Airbnb, accountants (In Extenso…). → Step 3.
2. **Official portals** — URSSAF, DGFIP/SIE, autoroutes (Ulys/APRR/ASF invoices): the document exists on the portal; either fetch it if a session is available or list it for Nicolas.
3. **Internal / no real receipt** — salary transfer to N26, internal account-to-account transfers, Qonto fees (Qonto issues its own invoice under Settings → Billing). Suggest marking them **not required** in the Qonto app (no public API endpoint for that flag — it's a UI action).
4. **Small card tickets** (restaurants, transport, parking) with no email trace → propose marking **lost** in the Qonto app; don't waste time hunting them.

## Step 3 — Recover & attach (email route)

Same rules as `/tidy-mail` (see that skill for the full procedure): perso mailbox (`gog -a perso`) justifies **Gybe**, pro mailbox (`gog -a qraft`) justifies **Qraft**.

For each recoverable transaction:

1. Search the mailbox by merchant + amount + date (`gog gmail search ... --json`; no infix matching — try spelling variants).
2. **Check `attachment_ids` again right before uploading** — Nicolas often photographs paper receipts on the spot; never duplicate.
3. Upload: `uv run python ~/.claude/skills/tidy-mail/scripts/qonto.py upload --org <org> --tx <id> --file <pdf>` (re-checks attachments, refuses duplicates). HTML-only receipts (Apple, Google Play, shops): render them first with `~/.claude/skills/tidy-mail/scripts/html_to_pdf.py` — works locally, not in the cloud routine (no Chrome: report instead). A receipt from one mailbox can belong to the other org: `qonto.py match` searches both and shows the card digits.
4. Re-run the audit to confirm the count went down.

## Reporting

Whatever the entry point (interactive or routine), end with: before → after counts per org, total amount still unjustified, what was attached (transaction IDs), and the residual list split by triage class so Nicolas can do the lost/not-required marking in the app in one pass.
