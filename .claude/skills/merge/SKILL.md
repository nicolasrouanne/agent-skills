---
name: merge
description: "Merge a PR (with merge commit) and prune merged branches, or enable GitHub auto-merge with --auto. Usage: /merge [--auto] [pr-number]"
title: /merge
parent: Skills
permalink: /skills/merge/
nav_order: 3
---

# Merge PR and Clean Up

Merge a pull request using a merge commit, then prune stale local branches.

With `--auto`, enable GitHub auto-merge instead of merging: GitHub merges the PR by itself once every required review and status check has passed. Nothing is merged until the repo's own rules are satisfied, so this needs no per-PR merge approval.

## Your Task

1. **Identify the PR**:
   - If a PR number or URL is provided as an argument, use that.
   - Otherwise, detect the current branch and find its associated PR:
     ```bash
     gh pr view --json number,title,state,mergeStateStatus
     ```
   - If no PR is found, tell the user and stop.

2. **Check PR is ready**:
   - Verify the PR state is `OPEN`.
   - Without `--auto`: if `mergeStateStatus` is `BLOCKED`, `BEHIND`, or `DIRTY`, warn the user and stop.
   - With `--auto`: auto-merge only applies while the PR is `BLOCKED` by required checks or reviews. For any other status, stop and explain:
     - `CLEAN` or `UNSTABLE`: nothing blocks the PR, it could be merged right now. That is a direct merge and needs per-PR approval: ask the user, then run `/merge` without `--auto`.
     - `BEHIND` or `DIRTY`: the branch needs an update or a conflict fix first.
     - `UNKNOWN`: GitHub is still computing; retry in a few seconds.

3. **Merge the PR** (no `--auto`):
   ```bash
   gh pr merge <number> --merge
   ```
   - Always use `--merge` (merge commit), never squash or rebase.
   - This command prompts for permission on purpose. The prompt is the merge guard: do not work around it.

4. **Enable auto-merge** (`--auto`), two commands:
   ```bash
   gh pr view <number> --json id -q .id
   ```
   ```bash
   gh api graphql -F id=<PR_NODE_ID> -f query='mutation($id: ID!) { enablePullRequestAutoMerge(input: {pullRequestId: $id, mergeMethod: MERGE}) { pullRequest { number autoMergeRequest { enabledAt mergeMethod } } } }'
   ```
   - Never use `gh pr merge --auto` for this. When nothing blocks the PR, gh silently merges it immediately instead of enabling auto-merge, which is exactly the merge the guard exists to prevent.
   - Report the result: the PR will merge by itself, with a merge commit, once its requirements are met.

## Important

- Always use merge commits (`--merge` / `mergeMethod: MERGE`), per project git preferences.
- Never use `--admin` or any other bypass of required reviews or checks.
- If the merge or the mutation fails, show the error and do not proceed to cleanup.
