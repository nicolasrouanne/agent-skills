---
name: notion-note
description: Write an internal note in the Qraft Notion Tech subpage (French, long-form voice) from the current session, a file, or a topic. Internal only — never published or cross-posted.
title: /notion-note
parent: Skills
permalink: /skills/notion-note/
nav_order: 5
---

# Notion Note

Internal write-up in the Qraft Notion **Tech** subpage: infra, tooling, process, TMBA decks. Not communication — for the blog and the networks, use `/publish`.

Voice: `.claude/knowledge/writing-style.md`, universal voice + "Long-form" section. Read it before drafting.

## Argument forms

- `/notion-note` — write up the current session.
- `/notion-note ./notes/meeting-notes.md` — turn those notes into a page.
- `/notion-note "topic"` — write about that topic, ask clarifying questions if needed.

## Workflow

1. Gather context from the session, the file, or the topic.
2. Propose a title, let Nicolas edit it.
3. Draft in **French**.
4. **Sensitive-terms scan**: write the draft to a scratchpad file and run `~/dev/claude/scripts/scan_sensitive.sh <file>`. The page is internal: on exit 1, show the matches and ask whether they're acceptable there. Exit 2 (terms list unreachable) → fail closed until the scan can run.
5. Create the page with the local Notion MCP: plain page (no database properties), parent page `189218ed56d78019b206d49417bafa31` (`Tech` in qrafttech), optional icon emoji matching the topic.
6. Return the page URL.

## Images

The Notion MCP can't upload files: use the REST API (`Notion-Version: 2025-09-03`) with `NOTION_TOKEN_WORK` from `~/.zshrc`, never printed.

1. Upload: `POST /v1/file_uploads` with `{"filename", "content_type"}` → `id` + `upload_url`, then `POST <upload_url>` as multipart (`file=@shot.jpg`) → `status: uploaded`.
2. Insert: `PATCH /v1/blocks/<page_id>/children` with `{"after": "<block_id>", "children": [{"type": "image", "image": {"type": "file_upload", "file_upload": {"id": "…"}, "caption": […]}}]}`.
3. Replace: the API can't swap the file of an existing image block — insert the new one after it, then `DELETE /v1/blocks/<old_id>`.
