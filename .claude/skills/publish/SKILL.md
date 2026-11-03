---
name: publish
description: Turn a piece of content into a qraft.tech blog article (FR + EN) plus a LinkedIn and an X post, all scheduled on the next free Mon/Thu slot at least 48h out. No validation step — the 48h are the review window.
title: /publish
parent: Skills
permalink: /skills/publish/
nav_order: 11
---

# Publish

One gesture: a source becomes a blog article in the website repo (FR + EN, one PR on `qrafttech/website`) and a LinkedIn + X post in post-bridge, all scheduled on the same slot. **No validation step**: the slot is at least 48h out, and those 48h are Nicolas's review window, on the PR's Vercel preview. Cancelling is cheap (see the end).

Voice: read `.claude/knowledge/writing-style.md` first — "Long-form" for the article, "LinkedIn / X" for the posts.

## Source

`/publish <source>`:

- *(no argument)* — the current session: what was built, decided, learned.
- an article URL — rewrite or adapt it.
- a TMBA — the page in the Talks data source (`1f9218ed-56d7-80b5-95d8-000bd84ce25f`) + its Fireflies transcript (`Transcript` property → `fireflies_get_transcript`).
- an idea note from `~/work/vault/comms/posts/` — the note body holds the context and sources. It's an idea pool: no status to update afterwards.

If the source is too thin for an article (one-liner, no real detail, no code), say so and stop rather than pad.

## 1. Pick the slot

1. List scheduled posts: post-bridge `list_posts` (status scheduled).
2. Slot = first **Monday or Thursday, 7:30 Europe/Paris**, at least **48h from now**, with no scheduled post that day. Compute the UTC time with the timezone, don't hardcode it: `date -u -d 'TZ="Europe/Paris" <YYYY-MM-DD> 07:30' +%FT%TZ` (05:30Z in summer, 06:30Z in winter).
3. Dedup: if a scheduled post or an existing article already covers the same subject, stop and say which one. Articles are the `content/blog/*/{fr,en}.md` files on `qrafttech/website` main, plus the open PRs that add some (`gh pr list --repo qrafttech/website --json number,title,files`). Their `date` front matter is the day they go out: a day taken by an article but not by a post is taken too.

Cadence is 2 posts/week, Mon + Thu. Never schedule twice the same day, never closer than 48h.

## 2. Write the article

- English first, then French. Long-form register from `writing-style.md`: the spirit and tone are fixed, the composition is free — shape each article around its own story, no template.
- **Sensitive-terms scan (required)**: write each version to a scratchpad file and run `~/dev/claude/scripts/scan_sensitive.sh <files>`. Exit 1 → show the matches and **stop**: with no validation step, a hit is the one case where Nicolas must decide (rewrite around it, or clear that specific match). Exit 2 (terms list unreachable) → fail closed, don't publish.

## 3. Open the article PR

The article lives in `qrafttech/website`, format in its README ("Blog" section). Work in a clone of the repo (the local checkout if there is one, else `gh repo clone qrafttech/website` into the scratchpad), on a branch `blog/<slug-fr>` from an up-to-date `origin/main`.

```
content/blog/<slug-fr>/
  fr.md
  en.md
  *.jpg / *.png   # the article's images
```

Each file starts with its front matter:

```yaml
---
title: "Auditer ses skills Claude Code"
slug: auditer-ses-skills-claude-code
date: 2026-10-05
author: "Nicolas Rouanne"
---
```

- **slug**: the slugified title of that language: `node -e 'console.log(process.argv[1].normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase().replace(/[^a-z0-9]+/g,"-").replace(/^-+|-+$/g,""))' "<title>"`. Set once, it is the URL: never change it after the merge. The folder is the FR slug; if it already exists, pick another title.
- **date**: the slot day, `YYYY-MM-DD`. That morning (Europe/Paris), the website's `publish-blog` workflow merges the PR and the article goes live, before the posts. Without `date`, it is a draft and the PR is never merged.
- **cover**, **excerpt**: optional. `cover: cover.jpg` is a file of the folder; `excerpt` defaults to the first paragraph.

Body in Markdown (GFM):

- Callouts: a quote whose first line is `> [!NOTE]`, `> [!TIP]` or `> [!WARNING]`.
- Images: the file in the folder, referenced by name, with the caption as title: `![alt](shot.jpg "caption")`. One file serves both languages unless the image has text in it.
- Links to other articles: internal paths, `/blog/<slug-fr>` or `/en/blog/<slug-en>`.

Commit, push, and open the PR: title `blog: <FR title>`, body = the slot and the two public URLs. **Don't merge it, and don't enable auto-merge**: the website's `publish-blog` workflow merges it on the morning of its `date`, without an approval, unless the PR is closed, a draft, has a review requesting changes, failing checks or a conflict with main. The branch must be `blog/<slug-fr>`, otherwise the workflow ignores it. Wait for the Vercel check and take the preview URL from it (`gh pr checks <n>`, or the vercel bot's comment): drafts and scheduled articles show there, marked "Programmé".

### Images

For app screenshots, Playwright with the system Chrome (`channel: 'chrome'`, plus `--enable-unsafe-swiftshader` for WebGL maps in headless) at `deviceScaleFactor: 2`, exported as JPEG ~80 % at 2400 px. Hide third-party branding with injected CSS or DOM edits before the shot rather than cropping.

Public URLs: `https://qraft.tech/blog/<slug-fr>` and `https://qraft.tech/en/blog/<slug-en>`.

## 4. Schedule the posts

post-bridge accounts: LinkedIn `75783`, X `75789`. One `create_post` with `scheduled_at` = the slot (UTC):

- **LinkedIn**: FR by default, `writing-style.md` LinkedIn / X section. Link to the qraft.tech article in the body.
- **X**: a long, detailed version in `platform_configurations` (the account has X Premium: check `has_x_premium` with `list_social_accounts`; ~250 characters only if it is false). Same substance as LinkedIn, more detail (the setup, the gains, the limits), up to 4 images in `platform_configurations.twitter.media`. post-bridge strips links and bare domains from X text, so the links go in `first_comment`, and file names that look like domains (`CLAUDE.md`, `orca.yaml`) go in Unicode monospace.
- **Unicode at scheduling time**: LinkedIn/X don't render markdown. Technical identifiers in Unicode monospace (𝚌𝚑𝚊𝚝.𝚊𝚜𝚔), sparse Unicode-bold subheadings, bullets with `-`. Never whole sentences.
- **One image**, taken from the article: one of its images, a headless Chrome screenshot, or a rendered HTML dataviz. Upload with `upload_media`, attach to the post.
- Run the sensitive-terms scan on the two post texts too, same rules as step 2.

Quote tweets and LinkedIn reposts aren't supported by post-bridge: don't attempt them.

## 5. Report

```
Programmé : <jour> <date> <heure>
Article : PR <website PR URL> → preview <Vercel preview URL>
Publié sur : <qraft.tech FR URL> / <qraft.tech EN URL>
Posts : LinkedIn <post-bridge id>, X <post-bridge id>
Merge : automatique le <date> au matin (passer la PR en draft pour la retenir)
Annuler : fermer la PR + supprimer le post dans post-bridge
```

## Cancel or move

- **Hold**: convert the PR to draft (`gh pr ready --undo <n>`): the workflow skips it, and the posts still go out at their slot, so move or delete them too. Nicolas can't request changes on a PR pushed under his own account, so draft is the way.
- **Cancel**: close the PR (once merged: a PR that removes `date` from both files), `delete_post` in post-bridge.
- **Move**: new `date` in both files (a commit on the PR, or a new PR once merged) + `update_post` with the new `scheduled_at` — same 48h and free-slot rules.
- **Edit after review**: if a post changes a verdict or a figure, fix the article too (FR and EN), and vice versa.
