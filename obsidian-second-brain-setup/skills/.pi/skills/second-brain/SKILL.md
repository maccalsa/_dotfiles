---
name: second-brain
description: Use this skill when working with the user's Obsidian Markdown vault as a second brain. It defines where to store notes, how to search, how to avoid duplicate knowledge, and how to use Graphify before brute-force reading.
---

# Second Brain Skill

You are operating inside the user's Obsidian vault.

## Prime directive

This vault is not a dumping ground. It is a human-reviewable knowledge system.

Prefer:
- small notes
- clear links
- source/context
- reviewable summaries
- durable knowledge

Avoid:
- giant unstructured summaries
- duplicate notes
- overwriting human-written files
- treating chat history as memory
- storing uncertain claims as facts

## Folder rules

- `00-Inbox/` = raw captures, unresolved ideas, unprocessed agent output.
- `01-Daily/` = daily notes, tasks, logs.
- `02-Projects/` = active outcomes with deadlines.
- `03-Areas/` = ongoing responsibilities.
- `04-Resources/` = articles, transcripts, research notes.
- `05-Permanent/` = distilled, durable understanding.
- `06-Agent/` = agent logs, retrieval traces, generated summaries.
- `07-Reviews/` = weekly/monthly reviews.
- `90-Archive/` = stale or completed material.

## Graphify output vs Obsidian graph

The CLI writes `graphify-out/graph.json` (machine index) and `graphify-out/GRAPH_REPORT.md` (human-readable report). Graphify’s report used to embed thousands of wikilinks like `[[_COMMUNITY_Community 1234|Community 1234]]` for cluster navigation. Obsidian’s **Graph** treats every wikilink as an edge and every distinct target as a node, so `GRAPH_REPORT.md` became a hub with thousands of ghost “notes”.

**Mitigations:**

1. **`brain-graph`** (dotfiles) runs `graphify update`, then **rewrites those lines to plain bullets** so Obsidian never sees `_COMMUNITY_` wikilinks. Re-run `brain-graph` after each `graphify` refresh if you invoke `graphify` directly.
2. **Excluded files:** Settings → Files and links → **Excluded files** → `graphify-out/**` (also in `.obsidian/app.json` as `userIgnoreFilters`) keeps tool output out of search; behavior vs graph can vary by Obsidian version.
3. **Graph filter:** set the Graph search box to **`-path:graphify-out`** and leave it on (can be persisted in `.obsidian/graph.json` as `"search"`).

## Before answering questions from the vault

1. Check whether `graphify-out/GRAPH_REPORT.md` exists.
2. Check whether `graphify-out/graph.json` exists.
3. Prefer graph/index clues before scanning many Markdown files.
4. Use Obsidian CLI search where possible:
   - `obsidian search query="..."`
5. Read only the most relevant notes.
6. Cite the note paths used in your answer.

## When capturing new knowledge

Use this shape:

```markdown
---
type: note
source: agent
status: needs-review
created: YYYY-MM-DD
confidence: low|medium|high
tags:
  - inbox
---

# Title

## Summary

## Why this matters

## Source / context

## Links

- [[Related Note]]

## Follow-up

- [ ] Review this note
```

## When unsure

Write to `00-Inbox/` with `status: needs-review`.

## Never do this

- Do not delete notes unless explicitly asked.
- Do not rewrite a permanent note without first preserving the original.
- Do not create a new folder structure without asking.
- Do not invent sources.
