# Inbox triage after distilled import

Use this after [`brain-import-distilled`](../bin/brain-import-distilled) has created notes under `00-Inbox/`. Work in **small batches** so the vault stays understandable.

Set `SECOND_BRAIN` to your vault root before running the importer (for example `export SECOND_BRAIN="$HOME/dev/SecondBrain"`). Defaults to `~/SecondBrain` if unset.

The importer looks for `distilled/manifest.json` in this order: `--distilled-root`, then `$DISTILLED_ROOT`, then `./distilled` from your **current working directory** (so `cd` into the tree that contains `distilled/` before running, unless you pass an explicit path).

For **repeatable sessions** (pick a theme, do 10–20 notes, then stop), use [inbox-processing-session.md](inbox-processing-session.md).

## Principles

- The vault is for **durable, reviewable** knowledge—not a dump. Treat distiller output as **draft** until you endorse it.
- Prefer **small notes**, **clear links**, and **honest confidence** in front matter.
- Folder rules live in the second-brain skill (`skills/.pi/skills/second-brain/SKILL.md`).

## End state for each promoted note

Importer notes used a staging section **`## Distilled content`**. After triage, that heading should **disappear**: fold that material into **`## Summary`**, **`## Why this matters`**, and the body so the note reads as if you wrote it that way. Remove duplicate `# Title` lines that only existed under Distilled content.

**Front matter** should align with the skill’s “When capturing new knowledge” shape (`type`, `source`, `status`, `created`, `confidence`, `tags`). **Remove importer-only keys** when you promote: `distilled_category`, `conversation_id`, `distiller_outcome`, `value_score`, `distiller_source_file`. If you need a paper trail, put UUID / export path as bullets under **Source / context**, not in YAML.

**Tags:** remove `inbox`, `distilled`, and `distilled-*` when the file leaves `00-Inbox/`. Add real topic tags (tool, domain, area).

**Filename:** rename to a descriptive slug; **drop** the `distilled-` prefix and category token from the filename.

## Batch size

- **Deep pass** (restructure, merge, rewrite, move): **10–20 notes per session**, or one **theme** (e.g. music, Elixir) until that slice is clean. Quality drops if you go much larger in one sitting.
- **Light pass** (purge junk, skim, quick archive): **~50 notes** can work when you are not rewriting prose.
- After a meaningful batch of moves, run **`brain-graph`** so Graphify matches the vault.

## Promotion checklist (copy per note)

- [ ] Fold **Distilled content** into Summary / body; remove the `## Distilled content` heading and duplicate title.
- [ ] Strip migration YAML (`distilled_*`, `conversation_id`, `distiller_*`, `value_score`) or move into **Source / context** if you want audit text.
- [ ] Set `confidence:`; set `status:` (e.g. `ready` or drop `needs-review` when satisfied).
- [ ] Replace tags; remove `inbox` when leaving Inbox.
- [ ] Rename file (no `distilled-` prefix).
- [ ] Move to PARA folder; run `brain-graph` after the batch.

## Checklist (per note or small group)

### 1. Restructure if necessary

- **Target:** no `## Distilled content` in the final file—content lives in Summary / Why / main sections.
- Split oversized notes into two files if they cover unrelated topics; link them with `[[wikilinks]]`.
- Promote stable procedures into clear step lists; demote chatty framing.

### 2. Combine notes

- Search the vault for the same topic (`obsidian search` or Graphify report) before keeping two files.
- Pick one **canonical** note; merge unique facts into it; leave a short stub that links to the winner, or delete the loser after merge (see purge).
- When merging, preserve provenance in **Source / context** on the surviving note if useful (optional; not required in YAML).

### 3. Purge notes

- Delete (or move to `90-Archive/`) notes you will never use—**low value**, wrong domain, or **duplicates** fully absorbed elsewhere.
- Do not keep notes “just in case” if they fail the “would I link this in six months?” test.
- The second-brain skill: do not delete unless you mean to; archiving is fine for “maybe later.”

### 4. Front matter

- Align with the skill template: `type`, `source`, `status`, `created`, `confidence`, `tags` (adjust fields to match how you use the vault).
- After you rewrite the note, `source: human` is reasonable; keep lineage in **Source / context** if it matters.
- Add `updated: YYYY-MM-DD` when you materially edit (optional but helpful).

### 5. Move to the correct PARA folder

Rough guide (judgment beats rules):

| You decided it is…            | Typical folder        |
|------------------------------|------------------------|
| Raw / not yet placed         | `00-Inbox/`           |
| An active outcome with a deadline | `02-Projects/` |
| Ongoing responsibility       | `03-Areas/`           |
| Reference / research / cheat-sheet | `04-Resources/` |
| Endorsed durable understanding | `05-Permanent/`     |
| Stale or done                | `90-Archive/`         |

**Distilled category hints (not automatic):**

- `how-to` → often `05-Permanent` if it is your repeatable procedure; `04-Resources` if it is generic reference you do not want as “canonical.”
- `project-ideas` → `02-Projects` when you commit; otherwise archive or delete.
- `useful-knowledge` → usually `04-Resources` first; promote to `05-Permanent` only when you stand behind it long term.

After a batch of moves, run `brain-graph` so Graphify matches the vault.

## Example: before / after (fictional)

**Before (import shell):**

```markdown
---
distilled_category: how-to
conversation_id: "…"
tags: [inbox, distilled, distilled-how-to]
---
# Baking sourdough
## Summary
## Distilled content
# Baking sourdough
Mix flour and water…
```

**After (promoted):**

```markdown
---
type: note
source: human
status: ready
created: 2026-05-13
updated: 2026-05-13
confidence: medium
tags:
  - cooking
  - sourdough
---
# Baking sourdough

## Summary

Mix flour and water, then fold daily until the dough is strong.

## Why this matters

…

## Source / context

- Prior import category: how-to (optional audit line)

## Links

## Follow-up
```

## Optional rhythm

- **Daily / weekly:** clear a fixed number of inbox notes using the steps above.
- **When inbox is empty:** run a short review in `07-Reviews/` if you use it.
