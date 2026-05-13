---
name: research-to-obsidian
description: Use this skill when researching a topic online and saving the findings into the user's Obsidian vault.
---

# Research to Obsidian Skill

You research topics and save useful findings into the Obsidian vault.

The goal is not to dump information. The goal is to create reviewable, sourced, reusable knowledge.

## Folder policy

Use these folders:

- `04-Resources/Web-Research/` for source notes
- `05-Permanent/` for distilled knowledge
- `06-Agent/Research-Logs/` for research logs

## Research workflow

For every research task:

1. Clarify the research question internally.
2. Search the web using available web tools.
3. Prefer primary sources:
   - official docs
   - original blog posts
   - GitHub repos
   - standards/specifications
   - vendor documentation
4. Use secondary sources only to add perspective.
5. Do not trust SEO content unless there is no better source.
6. Create source notes for genuinely useful sources.
7. Create one synthesis note.
8. Create one research log.
9. Mark anything uncertain clearly.
10. Do not create permanent conclusions without sources.

## Source note format

Each source note must use this format:

```markdown
---
type: source-note
status: needs-review
source: web
created: YYYY-MM-DD
tags:
  - research
---

# Source: TITLE

URL: SOURCE_URL

## Why this source matters

## Key points

## Useful quotes or exact details

Keep quotes short.

## My notes

## Related

- [[Related Topic]]
```

## Synthesis note format

The synthesis note goes in `05-Permanent/`.

```markdown
---
type: permanent-note
status: needs-review
source: synthesized-from-web-research
created: YYYY-MM-DD
confidence: low|medium|high
tags:
  - permanent
---

# TITLE

## Claim

One clear claim or conclusion.

## Explanation

## What this means for me

## Evidence

- [[Source Note 1]]
- [[Source Note 2]]

## Open questions

## Next actions
```

## Research log format

The research log goes in `06-Agent/Research-Logs/`.

```markdown
---
type: research-log
created: YYYY-MM-DD
status: complete
---

# Research Log: TOPIC

## Research question

## Searches performed

## Sources used

## Sources rejected

## Confidence

## Files created

## Recommended follow-up
```

## Rules

- Never overwrite human-written notes.
- Prefer appending if a relevant note already exists.
- Do not create more than 3-5 source notes unless explicitly asked.
- If the research is shallow, say so.
- If the answer depends on current information, include the date researched.
- Do not promote everything to permanent knowledge.
- Put uncertain findings in `04-Resources/Web-Research/`, not `05-Permanent/`.
