---
name: cra
description: "Suivi du temps : clôture mensuelle des CRA (Toggl → Billi → facture Qonto), réconciliation des sources, reconstitution des journées mal trackées."
title: /cra
parent: Skills
permalink: /skills/cra/
nav_order: 14
---

# CRA — Suivi du temps

Skill chapeau pour le suivi du temps de travail et la **clôture mensuelle** : Toggl propre → CRA Billi → facture Qonto. Orchestre les sources sans dupliquer leur logique.

## Sources de temps — hiérarchie des preuves

| Source | Rôle | Fiabilité |
|--------|------|-----------|
| **Toggl** | Source de vérité (temps réel) | Base — mais incomplète (timers oubliés, trous) |
| **Calendrier Google** (meetings) | Explique les trous : RDV, standups, déjeuners | Forte |
| **Sessions Claude Code** (`~/.claude/projects/*/`, timestamps des jsonl ; `toggl-activity <date>` les résume par créneau) | Reconstitue l'activité par projet, heure par heure | Forte |
| **Commits git / GitHub** | Confirme un sujet et un créneau précis | Appoint — donne peu au final : beaucoup de travail ne committe pas |

**Toggl + meetings + sessions Claude permettent de savoir à peu près tout.** Git/GitHub sert à confirmer un sujet (numéro d'issue → repo → client via `gh search issues "<titre>"`), pas à couvrir une journée.

## La passe mensuelle (clôture)

C'est le cœur de `/cra <mois>`. Rodée sur août 2026, reproduite chaque mois. L'automation Orca « CRA » fait une première passe le 1er du mois à 6h47 (voir `schedule/README.md`) ; la passe locale sert à compléter et valider.

### 1. Nettoyer Toggl

- **Entrées sans projet** : identifier via le numéro d'issue (`gh search issues "<titre exact>"` → repo → client), les patterns de description, et l'historique des mois précédents (mêmes descriptions déjà classées). Réattribuer par `PUT /workspaces/2584215/time_entries/{id}` avec `project_id`, puis relire.
- **Timers oubliés** (>10h), pauses déjeuner manquantes : voir `/toggl-calendar`.

### 2. Reconstituer les journées mal trackées

Pour chaque jour ouvré vide ou < 3h tracké :
- timeline Toggl exacte (⚠️ l'API renvoie de l'**UTC** — toujours convertir en heure de Paris avant de raisonner) ;
- événements calendrier du jour (meetings = trous légitimes ou temps client) ;
- sessions Claude Code : histogramme d'événements par heure et par projet ;
- commits git du jour en confirmation.

Créer les entrées manquantes (`POST /time_entries`, `created_with: "claude-cra"`) uniquement sur indices convergents ; sinon proposer à Nicolas. Ne jamais chevaucher l'existant ni combler un déjeuner. Congés confirmés par Nicolas = journée vide légitime.

### 3. Ventiler par mission

```bash
cd ~/toggl && uv run missions.py <YYYY-MM>
```

`missions.py` (repo privé `nicolasrouanne/toggl`) contient **le mapping de référence** projet Toggl → mission, applique l'arrondi carry-forward (0,5 j, plafond 1,0 j/jour/mission — Billi refuse toute durée hors `{0, 0.5, 1.0}`) et exclut le perso. Un projet non mappé est signalé : l'ajouter à `missions.py` (nouveau projet Startup Studio → R&D / Innovation par défaut).

### 4. Créer / mettre à jour les CRA Billi (drafts)

Voir « Billi — API » ci-dessous. Règles :
- **Un jour déjà déclaré dans un CRA = vérité** : ne jamais supprimer ni réduire un jour déclaré ; compléter seulement.
- Ne toucher qu'aux CRA en `draft` — jamais `pending_signature` ni `signed`.
- Créer en draft, **jamais soumettre** : l'envoi en signature est le geste de Nicolas.

### 5. Facturer (après validation)

Une fois le CRA client validé/signé : facture Qonto en **brouillon**, modelée sur la précédente du client.

```bash
# Modèle : dernière facture du client
GET https://thirdparty.qonto.com/v2/client_invoices?per_page=100   # Authorization: <org_id>:<api_key>
# Création en brouillon (le numéro définitif est attribué à la finalisation)
POST https://thirdparty.qonto.com/v2/client_invoices
  {"client_id": ..., "status": "draft", "issue_date": ..., "due_date": <+30j>,
   "performance_start_date": "<1er du mois>", "performance_end_date": "<dernier jour>",
   "currency": "EUR", "header": ..., "payment_methods": {"iban": ...},
   "items": [{"title": ..., "description": "Nicolas Rouanne", "quantity": "<jours>",
              "unit": "day", "unit_price": {"value": "<TJM>", "currency": "EUR"}, "vat_rate": "0.2"}]}
```

Credentials : 1Password `chezmoi_qonto_qraft` (vault `AI Agents`), champs `organization_id` + `api_key`. Règle : **CRA envoyé en signature avant de finaliser la facture** — les deux doivent raconter la même chose. La finalisation/l'envoi restent le geste de Nicolas.

## Billi — API

- **App** : https://app.billi.so | **API** : https://api.billi.so
- **Credentials** : 1Password `chezmoi_billi` (vault `AI Agents`) — email via `--fields username`, password via `op read`.
- **Auth** : OAuth password grant. ⚠️ **Le token expire vite** (< 1h) : re-authentifier avant chaque batch d'appels, ne jamais réutiliser un token stocké d'une étape précédente.

```bash
# Token
curl -s -X POST https://api.billi.so/oauth/token -H "Content-Type: application/json" \
  -d '{"grant_type":"password","email":"<email>","password":"<password>"}'
# CRA (paginé : ?page=N, filtrer freelancer.id == 166 côté client)
curl -s https://api.billi.so/activity_reports -H "Authorization: Bearer <token>"
# Créer un CRA (draft)
POST /activity_reports {"format":"billi","month":"YYYY-MM-01T00:00:00.000Z","mission_id":<id>}
# Remplir : jours nouveaux SANS id
PUT /activity_reports/<cra_id> {"activities_attributes":[{"date":"YYYY-MM-DD","duration":0.5,"mission_rate_id":<rate_id>}]}
# Modifier un jour existant : AVEC son id (sinon doublon)
PUT /activity_reports/<cra_id> {"activities_attributes":[{"id":<activity_id>,"duration":1.0}]}
```

États : `draft` → `pending_signature` (envoyé par Nicolas) → `signed`.

### Missions de Nicolas

IDs de missions, `rate_id`, TJM et règles de rattachement des clients : `missions.md` à côté de ce fichier (privé, jamais synchronisé vers le repo public).

Le mapping projet Toggl → mission est dans `~/toggl/missions.py` (source de vérité, repo privé).

## Règles de classement (facturable vs interne)

- **CRA client = uniquement le facturable.** Ne jamais facturer à un client du temps qui ne lui revient pas.
- **Contentieux** → `Qraft — Interne › Contentieux`, jamais facturé.
- **R&D / agentic engineering / Startup Studio** → `R&D / Innovation`, assiette CII, pas un CRA client.
- **Perso** (Perso, Immobilier, Bruno, Administratif Gybe) : exclu de tout CRA ; sert uniquement à expliquer un trou.

## Routines associées

| Routine | Cadence | Rôle |
|---|---|---|
| « Toggl check » (automation Orca, orca-host) | mar–sam 6h17 | Hygiène de la veille : réattributions, comblement, alertes (prompt versionné dans `toggl-calendar/schedule/`) |
| « CRA » (automation Orca, orca-host) | le 1er, 6h47 | Passe mensuelle sur le mois écoulé : ventilation + drafts Billi + DM récap (prompt versionné dans `cra/schedule/`) |

## Git commits — Extraction jours travaillés (collaborateurs sans Toggl)

```bash
git -C <repo> log --after="YYYY-01-01" --before="YYYY+1-01-01" --author="Nom" \
  --format="%ad" --date=format:"%Y-%m-%d" | sort -u | wc -l
```

Git est indicatif : un jour sans commit ≠ un jour sans travail ; un jour avec commit et sans CRA → probable oubli.

## Your Task

Quand l'utilisateur invoque `/cra` :

- `/cra <mois>` (ex. `aout`, `2026-08`) → **la passe mensuelle** ci-dessus, étapes 1 à 4. L'étape 5 (facture) seulement sur demande ou après validation explicite du CRA client.
- `/cra facture <client> <mois>` → étape 5 seule.
- `/cra toggl <mois>` → déléguer à `/toggl-calendar`.
- `/cra billi import/export` → déléguer à `/billi-cra`.
- `/cra git <repo> <année>` → extraction des jours de commits.
- `/cra compare <mois> <personne>` → réconcilier Toggl / Billi / git, tableau comparatif, signaler les écarts > 2 jours.

Toujours : montrer la ventilation avant d'écrire dans Billi, rendre compte de chaque écriture avec les IDs (annulable), et rappeler ce qui reste à faire (valider, envoyer, facturer).
