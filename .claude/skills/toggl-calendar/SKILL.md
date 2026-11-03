---
name: toggl-calendar
description: "Per-day, per-client timesheet calendar from Toggl. Shows work days per client per day, in 0.5-day increments with carry-forward rounding. Can also clean anomalies (overnight timers, missing lunch breaks) and reassign unattributed entries to clients."
title: /toggl-calendar
parent: Skills
permalink: /skills/toggl-calendar/
nav_order: 18
---

# Toggl Calendar

Generate a per-day, per-client timesheet for a calendar month (or range). Optionally clean anomalies and reassign entries.

## Configuration

- **Script**: `~/toggl/main.py`
- **Toggl API Token**: environment variable `TOGGL_API_TOKEN`
- **Workspace**: `2584215`
- **Work day**: 5.5 hours
- **Rounding**: carry-forward to nearest 0.5 — fractions accumulate across days so no hours are lost

## Toggl API

- **Base URL**: `https://api.track.toggl.com/api/v9`
- **Auth**: Basic auth with `{TOGGL_API_TOKEN}:api_token`
- **Entries**: `GET /me/time_entries?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`
- **Projects**: `GET /workspaces/2584215/projects?active=both`
- **Clients**: `GET /workspaces/2584215/clients`
- **Update entry**: `PUT /workspaces/2584215/time_entries/{id}` with JSON body

Use Python `urllib.request` for API calls (curl has issues with auth in some environments).

### Project mapping

The activity → Toggl project mapping (with project IDs) is the one in `schedule/prompt.md`, section « Mapping activité → projet Toggl », itself kept faithful to `missions.py`. Read it there; don't restate it here.

## Your Task

### 1. Generate timesheet (default)

1. **Parse the date range** from the user's message:
   - "January" / "january 2026" → `2026-01`
   - "last month" → previous calendar month
   - "january and february" / "jan-feb 2026" → `2026-01 2026-02`
   - No date → current month (script default)

2. **Run the script** via Bash:
   ```bash
   python3 ~/toggl/main.py 2026-01
   # or for a range:
   python3 ~/toggl/main.py 2026-01 2026-02
   ```

3. **Display the output** as-is — the script formats everything.

### 2. Clean overnight timers

When the user asks to check for anomalies or long entries:

1. Fetch entries via the API and find those with `duration > 36000` (> 10h)
2. Find the last real activity that evening from the Claude Code sessions and commits (see « Fill gaps » below) to determine realistic work hours
3. **Present findings** to the user — never modify without explicit approval
4. If approved, `PUT` the corrected `stop` time on the entry

### 3. Clean missing lunch breaks

When the user asks to check for uninterrupted entries:

1. Detect single entries that span across 12h-14h and last > 3h
2. Propose a split or reduction
3. **Wait for approval** before modifying

### 4. Reassign "Sans client" entries

When the user asks to attribute unassigned entries:

1. Fetch all entries for the period and filter those with no project or whose project has no client
2. List them with their descriptions
3. Match each entry to a project with the mapping above; confirm an issue number's repo with `gh search issues "<exact title>"`
4. **Present the proposed attribution** and wait for user corrections
5. Once approved, `PUT` the updated `project_id` on each entry
6. Re-run the script and update Notion (see below)

### 5. Fill gaps

Follow `/cra`: its « Sources de temps » table ranks the evidence and its step 2 « Reconstituer les journées mal trackées » is the method (overlaps, lunch, perso, `created_with`). Read the Claude Code sessions of the host: `toggl-activity <date>` (`.claude/routines/`) gives them by time slot, with commits and calendar.

Present the proposed entries; create them once approved.

## Saving to Notion

The timesheet is stored in the **CRA Toggl** page (`31b218ed-56d7-8001-9edd-e4076865f557`). When asked to save:

1. Fetch the page to get the current content
2. Use `update_content` to replace or append the month's table
3. Follow the existing format: `<table>` with header row, one row per day, yellow background total row

## Rounding Algorithm

For each client, across all days in order:
```
running   += raw_today          # raw = seconds / (5.5 × 3600)
new_total  = floor(running × 2 + 0.5) / 2   # round cumulative to nearest 0.5
day_value  = new_total − already_assigned
already_assigned = new_total
```

This ensures small fractions roll forward and are counted eventually, rather than being permanently discarded by per-day rounding.

## Guidelines

- **DO** run the script directly — don't re-implement the rounding logic inline
- **DON'T** hardcode the API token
- **DON'T** modify Toggl data without explicit user approval — always present findings first
