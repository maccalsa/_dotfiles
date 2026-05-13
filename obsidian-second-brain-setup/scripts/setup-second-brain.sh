#!/usr/bin/env bash
set -euo pipefail

VAULT="${SECOND_BRAIN:-$HOME/SecondBrain}"
BRAIN_BIN="${HOME}/.local/brain/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Setting up SecondBrain vault at: $VAULT"

mkdir -p \
  "$VAULT/00-Inbox" \
  "$VAULT/01-Daily" \
  "$VAULT/02-Projects" \
  "$VAULT/03-Areas" \
  "$VAULT/04-Resources/Web-Research" \
  "$VAULT/05-Permanent" \
  "$VAULT/06-Agent/Research-Logs" \
  "$VAULT/07-Reviews" \
  "$VAULT/90-Archive" \
  "$VAULT/templates" \
  "$VAULT/.pi/skills"

cat > "$VAULT/README.md" <<'EOF'
# SecondBrain

This vault is my local Markdown knowledge system.

Rules:
- Inbox is for capture, not storage.
- Projects are active outcomes.
- Areas are ongoing responsibilities.
- Resources are reference material.
- Permanent notes are distilled understanding.
- Agent notes must be reviewable by me.
EOF

cat > "$VAULT/00-Inbox/inbox.md" <<'EOF'
---
type: inbox
status: active
tags:
  - inbox
---

# Inbox

Raw thoughts, captures, and unresolved material go here.

## Unprocessed

EOF

cat > "$VAULT/06-Agent/agent-rules.md" <<'EOF'
---
type: agent-policy
status: active
tags:
  - agent
  - second-brain
---

# Agent Rules

Pi may write to this vault, but must follow these rules:

1. Prefer appending to existing relevant notes over creating duplicates.
2. New raw material goes to `00-Inbox`.
3. Durable lessons go to `05-Permanent`.
4. Project-specific material goes to `02-Projects`.
5. Always include source/context when adding knowledge.
6. Never silently overwrite human-written notes.
7. If unsure, create an inbox note marked `needs-review`.
8. Use links to connect notes, e.g. [[Project Name]], [[Concept Name]].
9. Agent-generated notes should include:
   - Created date
   - Source
   - Confidence
   - Why this matters
   - Suggested links
EOF

cat > "$VAULT/templates/source-note.md" <<'EOF'
---
type: source-note
status: needs-review
source: web
created: {{date}}
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
EOF

cat > "$VAULT/templates/permanent-note.md" <<'EOF'
---
type: permanent-note
status: needs-review
source: synthesized
created: {{date}}
confidence: low
tags:
  - permanent
---

# TITLE

## Claim

## Explanation

## What this means for me

## Evidence

## Open questions

## Next actions
EOF

cat > "$VAULT/templates/weekly-review.md" <<'EOF'
# Weekly Review - {{date}}

## Inbox processed

- [ ] 00-Inbox reviewed
- [ ] Agent notes reviewed
- [ ] Tasks reviewed
- [ ] Stale notes archived

## What did I learn this week?

## What keeps recurring?

## What should become a permanent note?

## What should be deleted?

## Useful links created

## Questions for Pi

-
EOF

cat > "$VAULT/.gitignore" <<'EOF'
# Generated graph/index output
graphify-out/

# Obsidian workspace state
.obsidian/workspace*
.obsidian/cache
.obsidian/plugins/*/data.json

# Trash
.trash/

# OS/editor junk
.DS_Store
Thumbs.db
*.swp
*.tmp
EOF

echo "Copying Pi skills..."
cp -R "$PACKAGE_ROOT/skills/.pi/skills/"* "$VAULT/.pi/skills/"

echo "Installing helper scripts to $BRAIN_BIN..."
mkdir -p "$BRAIN_BIN"
cp "$PACKAGE_ROOT/bin/"* "$BRAIN_BIN/"
chmod +x "$BRAIN_BIN"/brain-*

SHELL_RC="$HOME/.zshrc"
if [ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ] && [ ! -f "$SHELL_RC" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

PATH_HINT='export PATH="$HOME/.local/brain/bin:$HOME/.local/bin:$PATH"'

if [ -f "$SHELL_RC" ]; then
  if ! grep -q 'SECOND_BRAIN' "$SHELL_RC"; then
    {
      echo ""
      echo "# SecondBrain helper scripts"
      echo "export SECOND_BRAIN=\"$VAULT\""
      echo "$PATH_HINT"
    } >> "$SHELL_RC"
    echo "Updated $SHELL_RC with SECOND_BRAIN and PATH."
  elif ! grep -qF '.local/brain/bin' "$SHELL_RC"; then
    {
      echo ""
      echo "# SecondBrain: helper scripts (~/.local/brain/bin)"
      echo 'export PATH="$HOME/.local/brain/bin:$PATH"'
    } >> "$SHELL_RC"
    echo "Appended ~/.local/brain/bin to PATH in $SHELL_RC."
  else
    echo "Skipped shell rc update (SECOND_BRAIN and ~/.local/brain/bin already present)."
  fi
else
  echo "No $SHELL_RC found. Ensure this is in your shell config:"
  echo "export SECOND_BRAIN=\"$VAULT\""
  echo "$PATH_HINT"
fi

if command -v git >/dev/null 2>&1; then
  cd "$VAULT"
  if [ ! -d ".git" ]; then
    git init
  fi
  git add .
  git commit -m "Initial SecondBrain vault setup" || true
else
  echo "Git not found. Skipping Git initialisation."
fi

cat <<EOF

Done.

Next manual steps:

1. Open Obsidian.
2. Use: Open folder as vault.
3. Select: $VAULT
4. Enable CLI:
   Settings -> General -> Command line interface -> Enable
5. Restart your terminal.
6. Test:
   obsidian help

If 'obsidian' is not found, run:
   brain-link-obsidian-cli

Then try:
   brain-capture "First second brain note"
   brain-morning
   brain-status

EOF
