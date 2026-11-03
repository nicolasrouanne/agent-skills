---
name: tmba-process
description: 'Process a "Tech My Breath Away" meeting: move the Fireflies-created Notion page to the Talks database, and upload the video to Google Drive.'
title: /tmba-process
parent: Skills
permalink: /skills/tmba-process/
nav_order: 17
---

# Tech My Breath Away - Post-Meeting Processor

Process a "Tech My Breath Away" meeting: move the Fireflies-created Notion page to the Talks database, and upload the video to Google Drive.

## Your Task

### Step 1: Find the meeting in Fireflies

Search Fireflies for recent "Tech My Breath Away" meetings:
```
fireflies_search: "Tech My Breath Away" limit:5
```

Present the list to the user with dates and let them pick which meeting to process. If only one unprocessed meeting, confirm with the user.

### Step 2: Get full meeting data from Fireflies

Once the user selects a meeting, fetch the full meeting data using `fireflies_fetch` with the meeting ID. You need:
- The **Video URL** (field: `Video Url`)
- The **meeting date**
- The **title** (to find the matching Notion page)
- The **meeting ID** (appears in the Fireflies link on the Notion page)

### Step 3: Find and move the Notion page

The Fireflies integration auto-creates Notion pages in the Fireflies meetings data source
(`a40218ed-56d7-82b8-978e-07fb1c4b21c7`).

Search Notion for the meeting title (they typically contain "Tech My Breath Away" and "(Fireflies)").
The search result is large — filter it with a script on `properties.Title` + `parent.data_source_id`
rather than reading it all. List every TMBA page still in the Fireflies data source: more than one
may be pending (e.g. one missed the previous month).

Verify you found the right page by checking that its `Transcript` property URL ends with the
Fireflies meeting ID from Step 2.

Then **move the page** to the Talks database data source with `mcp__notion__API-move-page`:
- `parent`: `{"type": "data_source_id", "data_source_id": "1f9218ed-56d7-80b5-95d8-000bd84ce25f"}`
- The API may return a `validation_error` even though the move succeeded — re-read the page
  and check `parent.data_source_id` before retrying.

After moving, **update the page properties** with `mcp__notion__API-patch-page`:
- `Name`: Clean title, format as "Tech My Breath Away - [Topic]" (remove "🥐 Breakfast ️" and "(Fireflies)" / "(Recorded using Fireflies)" suffixes)
- `Date`: `{"date": {"start": "YYYY-MM-DD"}}` (date only, no time)
- `Speaker`: rich_text — extract from the meeting content (the main presenter). Ask the user if unclear.

### Step 4: Download video and upload to Google Drive

Download the video from the Fireflies CDN URL to the scratchpad, then upload with rclone:

```bash
# Download video (name it after the cleaned title)
curl -sSL -o "YYYY-MM-DD - Topic.mp4" "<VIDEO_URL>"

# Upload to Google Drive (restricted folder)
rclone copy "YYYY-MM-DD - Topic.mp4" tmba-videos: --retries 5 --low-level-retries 20

# Clean up
rm "YYYY-MM-DD - Topic.mp4"
```

The rclone remote `tmba-videos` is pre-configured with:
- `drive.file` scope (can only access files it creates)
- Locked to a specific folder

Name the video file descriptively: `YYYY-MM-DD - Topic.mp4` (matching the cleaned title).

**If rclone fails with `invalid_grant: token expired`**, the OAuth token needs a refresh. The
interactive prompt has no stdin in Claude Code, so run it with `--auto-confirm` in the
background — it opens the browser for the user to re-authorize:

```bash
rclone config reconnect tmba-videos: --auto-confirm
```

Tell the user to complete the Google consent in their browser, then retry the upload.

On orca-host there is no browser: ask the user to reconnect on the laptop, then copy the laptop's
`[tmba-videos]` section into the host's `~/.config/rclone/rclone.conf` (`chmod 600`).

### Step 5: Update the Video property in Notion

`drive.file` scope cannot see the folder's other files, but it *can* see the files rclone
created — so the Drive file ID is available programmatically:

```bash
rclone lsjson tmba-videos: | python3 -c 'import json,sys; [print(f["Name"], f["ID"]) for f in json.load(sys.stdin)]'
```

Build the link as `https://drive.google.com/file/d/<ID>/view` and set it on the Notion page's
`Video` property (url). Access follows the folder's sharing settings; no need to ask the user
for a shareable link.

### Step 6: Summary

Report what was done:
- Notion page moved to Talks database
- Properties set (Name, Date, Speaker)
- Video uploaded to Google Drive
- Any remaining manual steps

## Important Notes

- The video URL from Fireflies is **signed and expires**. Download promptly after fetching.
- Always confirm the meeting selection with the user before processing.
- If the Notion page has already been moved to the Talks database, warn the user and skip the move step.
- If the Fireflies MCP is unavailable, the GraphQL API works with the key in 1Password
  (`chezmoi_fireflies`, vault `AI Agents`): `{ transcript(id: "<ID>") { title date video_url } }`
  on `https://api.fireflies.ai/graphql` with `Authorization: Bearer <key>`. Reading 1Password
  may be blocked in auto mode — ask the user to run it if so.
