#!/usr/bin/env python3
"""List Qonto transactions missing a receipt (justificatif).

Scans every bank account of a Qonto organization and reports settled debit
transactions that have no attachment, excluding those whose receipt is
declared lost (attachment_lost) or not required (attachment_required=false).

Credentials, in order of precedence:
  1. Env vars QONTO_<ORG>_ORGANIZATION_ID / QONTO_<ORG>_API_KEY
  2. 1Password item `chezmoi_qonto_<org>` in vault "AI Agents"
     (fields: organization_id, api_key)

Usage:
  missing_receipts.py --org gybe
  missing_receipts.py --org qraft --since 2026-01-01 --min-amount 5
  missing_receipts.py --org gybe --json /tmp/missing.json
"""

import argparse
import json
import os
import subprocess
import sys
import urllib.request
from collections import Counter, defaultdict

API = "https://thirdparty.qonto.com/v2"
# Qonto's WAF rejects the default Python-urllib user agent with a 403.
UA = "curl/8.7.1"


def creds(org: str) -> str:
    prefix = f"QONTO_{org.upper()}_"
    org_id = os.environ.get(prefix + "ORGANIZATION_ID")
    api_key = os.environ.get(prefix + "API_KEY")
    if not (org_id and api_key):
        item = f"chezmoi_qonto_{org}"

        def op_field(field: str) -> str:
            out = subprocess.run(
                ["op", "item", "get", item, "--vault", "AI Agents",
                 "--fields", field, "--reveal"],
                capture_output=True, text=True, check=True)
            return out.stdout.strip()

        org_id, api_key = op_field("organization_id"), op_field("api_key")
    return f"{org_id}:{api_key}"


def get(auth: str, path: str, params: str = "") -> dict:
    url = f"{API}/{path}" + (f"?{params}" if params else "")
    req = urllib.request.Request(
        url, headers={"Authorization": auth, "User-Agent": UA,
                      "Accept": "application/json"})
    raw = urllib.request.urlopen(req).read().decode("utf-8")
    # strict=False: some transaction labels contain raw control characters.
    return json.loads(raw, strict=False)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--org", required=True, help="org slug, e.g. gybe or qraft")
    ap.add_argument("--since", default=None, help="only transactions settled on/after YYYY-MM-DD")
    ap.add_argument("--min-amount", type=float, default=0.0, help="skip amounts below this")
    ap.add_argument("--json", dest="json_out", default=None, help="also write the list to this JSON file")
    args = ap.parse_args()

    auth = creds(args.org)
    org = get(auth, "organization")["organization"]
    accounts = {a["id"]: a["name"] for a in org["bank_accounts"]
                if a["status"] == "active"}

    missing, excluded, scanned = [], Counter(), 0
    for acc_id, acc_name in accounts.items():
        page = 1
        while page:
            data = get(auth, "transactions",
                       f"bank_account_id={acc_id}&per_page=100&current_page={page}")
            for t in data["transactions"]:
                scanned += 1
                if t["side"] != "debit" or t["status"] != "completed":
                    continue
                if t["attachment_ids"]:
                    continue
                if t.get("attachment_lost"):
                    excluded["lost"] += 1
                    continue
                if not t.get("attachment_required", True):
                    excluded["not_required"] += 1
                    continue
                date = (t.get("settled_at") or t.get("emitted_at"))[:10]
                if args.since and date < args.since:
                    continue
                if t["amount"] < args.min_amount:
                    excluded["below_min_amount"] += 1
                    continue
                missing.append({
                    "account": acc_name,
                    "id": t["id"],
                    "date": date,
                    "label": t["label"],
                    "amount": t["amount"],
                    "currency": t["currency"],
                    "operation_type": t["operation_type"],
                })
            page = data["meta"]["next_page"]

    missing.sort(key=lambda t: t["date"], reverse=True)

    if args.json_out:
        with open(args.json_out, "w") as f:
            json.dump(missing, f, ensure_ascii=False, indent=1)

    by_month = defaultdict(list)
    for t in missing:
        by_month[t["date"][:7]].append(t)
    for month in sorted(by_month, reverse=True):
        txs = by_month[month]
        print(f"\n== {month} — {len(txs)} tx, {sum(t['amount'] for t in txs):.2f} EUR ==")
        for t in sorted(txs, key=lambda x: -x["amount"]):
            print(f"  {t['date']}  {t['amount']:>9.2f}  {t['operation_type'][:12]:<12} "
                  f"{t['label'][:42]:<42} [{t['account']}]  {t['id']}")

    total = sum(t["amount"] for t in missing)
    print(f"\n{org['slug']}: scanned {scanned} transactions across "
          f"{len(accounts)} accounts — {len(missing)} missing receipts "
          f"({total:.2f} EUR), excluded {dict(excluded) or 'none'}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
