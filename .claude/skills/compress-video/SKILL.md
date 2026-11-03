---
name: compress-video
description: Compress a video file using the local `compress-video` CLI (ffmpeg wrapper — 1080p, 24 fps, H.264 2500k, AAC 192k). Use when asked to compress, shrink, lighten or convert a video, or to concatenate clips.
title: /compress-video
parent: Skills
permalink: /skills/compress-video/
nav_order: 35
---

# Compress Video

Delegate to the `compress-video` CLI: `compress-video.sh`, next to this file, linked as `compress-video` on the PATH (`/opt/homebrew/bin` on the laptop, `/usr/local/bin` in the orca-host image). Do NOT build an ffmpeg command by hand — the script already has sane defaults and handles output naming, collisions and concatenation.

## Your Task

Given one or more video file paths:

1. **Resolve the paths** — expand `~`, verify each file exists.
2. **Run `compress-video`**:
   ```bash
   compress-video [ffmpeg output options] <input> [<input>...]
   ```
   - Everything before the input files is passed verbatim to ffmpeg as output options, after the defaults (so it overrides them).
   - Multiple inputs are concatenated with the concat demuxer (they must share codec parameters — same recording setup).
3. **Report the output path and size** — before/after (`du -h`), so the user sees the gain.

## Defaults (from the script)

`-vf "scale=-2:1080" -r 24 -c:v libx264 -b:v 2500k -preset medium -c:a aac -b:a 192k`

Output lands next to the first input, same name and extension. If the file exists, `_1`, `_2`… is appended. With several inputs the name gets a ` combined` suffix.

## Common overrides

| Ask | Options |
|-----|---------|
| Output as mp4 | `-f mp4` |
| No audio | `-an` |
| Smaller / larger | `-b:v 1500k` / `-b:v 4000k` |
| 720p instead of 1080p | `-vf scale=-2:720` |
| Different framerate | `-r 30` |

## Guidelines

**DO:**
- Use the CLI. If it's broken or missing a feature, fix it in `compress-video.sh`, next to this file.
- Keep the defaults unless the user asks for something specific — they're tuned for sharing (Slack, Drive, email).
- Show before/after size.

**DON'T:**
- Don't overwrite the source. The script never does; don't force it.
- Don't run several compressions in parallel — ffmpeg already saturates the CPU.

## Input Handling

- **Single file**: `/compress-video ~/Downloads/demo.mov`
- **With options**: `/compress-video -f mp4 -an ~/Downloads/demo.mov`
- **Several clips**: `/compress-video part1.mov part2.mov`
- **No argument**: ask for the file path.

## Tools Used

- **Bash**: `compress-video`, `du -h`.

## Dependencies

- ffmpeg: `brew install ffmpeg` on the laptop; in the orca-host image already
- laptop: `ln -sf ~/dev/claude/.claude/skills/compress-video/compress-video.sh /opt/homebrew/bin/compress-video`
