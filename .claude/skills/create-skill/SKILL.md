---
name: create-skill
description: Create a new Claude Code skill based on conversation context, a file, or a description of the skill's purpose.
title: /create-skill
parent: Skills
permalink: /skills/create-skill/
nav_order: 1
---

# Skill Creator

Create new Claude Code skills from context, descriptions, or examples.

## Your Task

1. **Gather context** from one of these sources:
   - Current conversation (default if no argument provided)
   - A file path passed as argument (e.g., `/create-skill ./notes/workflow-idea.md`)
   - A description passed as argument (e.g., `/create-skill "A skill to run tests and format output"`)

2. **Ask the user** using AskUserQuestion:
   - Skill name (propose one based on context, lowercase with hyphens)
   - Brief description (one sentence for the frontmatter)
   - Target location: user-level (`~/dev/claude/.claude/skills/`) or project-level (`./.claude/skills/`)
   - Any specific tools or MCP servers the skill should use

3. **Determine skill type** based on context:
   - **Workflow skill**: Multi-step process with clear phases
   - **Utility skill**: Single focused task
   - **Integration skill**: Interacts with external services via MCP

4. **Generate the SKILL.md** following the structure below

5. **Write the file** to the appropriate location. Filename MUST be `SKILL.md` (uppercase) — the GitHub Pages deploy looks for that exact name.

6. **Sync the docs** if this is a user-level skill in `~/dev/claude/`: run `python3 scripts/sync_docs.py` to regenerate the skill table in `README.md`.

7. **Remind the user** to commit the new skill and the regenerated tables together — CI rejects PRs where the tables drift from the filesystem.

## Skill File Structure

```markdown
---
name: skill-name
description: One sentence describing what this skill does.
# Jekyll nav (only needed for skills synced to the public mirror, published at nicolasrouanne.github.io/agent-skills):
title: /skill-name
parent: Skills
permalink: /skills/skill-name/
---

# Skill Title

Brief overview of what this skill accomplishes.

## Your Task

[The outcome, the constraints, and how to check the result. Number steps only where their order matters.]

## Guidelines

[DO and DON'T lists if applicable]

**DO:**
- Specific behaviors to follow
- Quality standards

**DON'T:**
- Anti-patterns to avoid
- Common mistakes

## Input Handling

[Document how arguments are interpreted]

- No argument: Use current conversation context
- File path: Read and process the file
- Description: Use as the basis for the task

## Tools Used

[List any specific tools, MCP servers, or integrations]

- Tool/MCP name: What it's used for

## Example Usage

```
/skill-name
/skill-name ./path/to/file.md
/skill-name "description of what to do"
```
```

## Guidelines

**DO:**
- Keep skills focused on a single purpose
- Match specificity to fragility: exact commands for fragile or destructive operations; the goal, constraints and how to verify for judgment work
- Document which tools/MCPs are needed
- Add example usage patterns
- Use AskUserQuestion for user decisions

**DON'T:**
- Create overly complex multi-purpose skills
- Hardcode values that should be configurable
- Skip the frontmatter (name and description are required)
- Assume tools are available without checking

## Placement Decision

**User-level (`~/dev/claude/.claude/skills/`)** for:
- Generic utilities useful across all projects
- Personal workflow preferences
- Skills that don't reference project-specific paths

**Project-level (`./.claude/skills/`)** for:
- Project-specific workflows (deploy, release, test)
- Skills that use project paths, scripts, or tools
- Team processes that should be shared via version control

## After Creation

Ask the user:
- "Would you like to test the skill now?"
- If user-level: "Would you like to commit and push to your claude repo?"
- If project-level: "Don't forget to commit this to your project repo."

## Example Prompts

**From conversation:**
```
User: I keep having to run these 5 commands every time I deploy
Claude: [discusses the workflow]
User: /create-skill
```
Creates a skill based on the deployment workflow discussed.

**From description:**
```
/create-skill "A skill to summarize meeting notes and extract action items"
```
Asks clarifying questions, then generates a meeting-notes skill.

**From file:**
```
/create-skill ./docs/release-process.md
```
Reads the document and creates a skill that automates the described process.
