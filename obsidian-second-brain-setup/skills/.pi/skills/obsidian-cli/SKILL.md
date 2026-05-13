---
name: obsidian-cli
description: Use this skill when interacting with Obsidian through the official Obsidian CLI.
---

# Obsidian CLI Skill

Use the `obsidian` command to interact with the running Obsidian app.

## Important

- Obsidian must be installed.
- Obsidian CLI must be enabled in Obsidian settings.
- Obsidian app should be running.
- Prefer CLI operations over raw filesystem scanning when searching, reading active notes, appending to daily notes, listing tasks, tags, and links.

## Useful commands

Search:

```bash
obsidian search query="search terms"
```

Open today's daily note:

```bash
obsidian daily
```

Append to today's daily note:

```bash
obsidian daily:append content="- [ ] Task"
```

Read active note:

```bash
obsidian read
```

List daily tasks:

```bash
obsidian tasks daily
```

List tags:

```bash
obsidian tags counts
```

## Rules

- Do not rely only on grep if Obsidian CLI can provide structured results.
- When writing notes, use Markdown and Obsidian links.
- When adding tasks, use Obsidian task syntax:
  - `- [ ] todo`
  - `- [x] done`
- Do not overwrite notes without explicit permission.
