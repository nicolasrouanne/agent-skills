---
name: qonto-invoices
description: "Analyse des factures clients Qonto par période de prestation (pas date d'émission) et compte de destination. Sortie HT/TTC, top clients, audit des cas ambigus."
title: /qonto-invoices
parent: Skills
permalink: /skills/qonto-invoices/
nav_order: 20
---

# Qonto Invoices

Bilan factures clients Qonto pour une année donnée, en raisonnant sur la **période de prestation** (et non la date d'émission), avec une vue par **compte de destination** (récupérés dynamiquement depuis l'organisation Qonto).

## Pourquoi cette skill

Le bilan annuel "factures émises en YYYY" donne un mauvais résultat car :
- Une facture émise début janvier YYYY concerne souvent décembre YYYY-1.
- Une facture émise en janvier/février YYYY+1 concerne souvent décembre YYYY.
- Certaines factures n'ont **pas** le champ `performance_date` rempli — il faut parser le mois en français (`"Prestations janvier 2025"`, `"…mai 2026"`, etc.) dans le `header` ou les `items`.

La skill applique une heuristique en cascade :

1. `performance_date` si renseigné
2. Sinon, mois français parsé dans `header` / `items[].title` / `items[].description`
3. Sinon, fallback sur `issue_date` (signalé dans la section audit)

## Script

- `aggregate.jq` (dans ce dossier) — toute la logique de filtrage et d'agrégation. Reçoit `year`, `window` (nb de mois après le 31/12 à scanner) et `accounts` (mapping IBAN → nom de compte, **construit dynamiquement** depuis l'API pour ne rien hardcoder dans le repo).

## Your Task

Quand l'utilisateur invoque `/qonto-invoices [année] [org]` (org : `qraft` par défaut, ou `gybe`) :

### 1. Identifiants

API REST Qonto, comme `/qonto-receipts` : header `Authorization: <organization_id>:<api_key>`. Variables `QONTO_<ORG>_ORGANIZATION_ID` / `QONTO_<ORG>_API_KEY` si elles sont définies, sinon 1Password `chezmoi_qonto_<org>` (vault `AI Agents`, champs `organization_id` + `api_key`).

### 2. Récupérer l'organisation et toutes les factures clients

Fichiers dans le scratchpad :

```bash
AUTH="$QONTO_QRAFT_ORGANIZATION_ID:$QONTO_QRAFT_API_KEY"
curl -s -H "Authorization: $AUTH" https://thirdparty.qonto.com/v2/organization > org.json
curl -s -H "Authorization: $AUTH" "https://thirdparty.qonto.com/v2/client_invoices?per_page=500" > invoices.json
jq '{total: .meta.total_count, got: (.client_invoices | length)}' invoices.json
```

`total` et `got` doivent être égaux. ⚠ Utiliser `per_page=500` (ou un nombre ≥ `total_count`) : avec `per_page=100`, la pagination Qonto trie par DESC et la concaténation page 1 + page 2 peut produire des doublons / oublis (bug observé).

### 3. Lancer l'agrégation

Le mapping IBAN → compte vient de `org.json`. **Ne jamais hardcoder un IBAN ni un nom de compte dans le repo.**

```bash
jq -r \
  --arg year "2025" \
  --arg window "2" \
  --argjson accounts "$(jq '[.organization.bank_accounts[] | {(.iban): .name}] | add' org.json)" \
  -f ~/dev/claude/.claude/skills/qonto-invoices/aggregate.jq \
  invoices.json
```

- Sans argument utilisateur : `year` = année en cours - 1 (cas le plus fréquent = bilan annuel).
- Si l'utilisateur dit "2024", "2025"… → `year` correspondant.
- `window=2` est le défaut raisonnable (couvre les factures émises jusqu'à fin février N+1).

### 4. Présenter le résultat

Affiche la sortie brute du script (déjà formatée), puis :

- **Mets en avant la section "À vérifier manuellement"** : factures avec `period_source = issue_date_fallback` (headers vides, placeholders non remplis, etc.). Pour chacune, propose une période corrigée basée sur le contexte (cadence client, type de prestation) et **demande confirmation à l'utilisateur** avant d'ajuster.
- Si l'utilisateur valide une exclusion, recalcule en filtrant et redonne les totaux. Pas besoin de re-fetch l'API.

### 5. Cas limites connus à signaler

| Symptôme | Cause probable | Action |
|---|---|---|
| Header vide sur une facture début janvier | Facture pour le mois précédent (donc année précédente) | Proposer d'exclure |
| Header avec `%mois%` / `%année%` littéraux | Template Qonto avec placeholder pas substitué | Signaler comme bug Qonto, déduire la période de la cadence |
| Un client apparaît avec 2 graphies (majuscules vs casse mixte) | Doublon côté Qonto | Suggérer un merge dans Qonto |
| `total_pages > 1` avec `per_page=100` | Ne pas paginer manuellement | Augmenter `per_page` à ≥ `total_count` |

## Options avancées

- **Filtrer un compte spécifique** : ajouter `| map(select(.account == "<nom>"))` dans le pipeline jq, ou faire un `select` en post.
- **Cumul HT par mois de prestation** : `group_by(.period[0:7])` au lieu de `group_by(.account)`.
- **Année partielle** : restreindre par `select(.period >= "YYYY-MM-01")` etc.

## Notes

- Le script ne traite que les factures **clients** (`/v2/client_invoices`). Pour les factures fournisseurs ou les notes de crédit, voir `/v2/supplier_invoices` / `/v2/credit_notes`.
- Les montants HT sont calculés comme `total_amount - vat_amount` (plus simple et exact que de sommer les `items[].subtotal`).
- L'IBAN du compte de destination est lu dans `payment_methods[0].iban` — vérifier qu'il n'y a pas de multi-IBAN par facture (à date, un seul moyen de paiement par facture).
