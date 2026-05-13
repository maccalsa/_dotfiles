# Obsidian + Pi + Graphify Second Brain Setup

This setup kit creates a local Markdown-based second brain suitable for:

- Obsidian as the human-facing note app
- Pi as the agent/research assistant
- Git as the safety/versioning layer
- Graphify as the optional graph/index layer
- Shell scripts for repeatable capture, review, graph refresh, and save workflows

It does **not** magically configure every Obsidian GUI setting. Obsidian still requires a small manual step: open the folder as a vault and enable the CLI inside Obsidian.

---

## What this creates

Default vault location:

```bash
~/SecondBrain
```

Vault structure:

```text
~/SecondBrain/
  00-Inbox/
  01-Daily/
  02-Projects/
  03-Areas/
  04-Resources/
    Web-Research/
  05-Permanent/
  06-Agent/
    Research-Logs/
  07-Reviews/
  90-Archive/
  templates/
  .pi/
    skills/
      second-brain/
      obsidian-cli/
      research-to-obsidian/
```

Helper commands installed into `~/bin`:

```text
brain-capture
brain-morning
brain-graph
brain-save
brain-status
brain-open
brain-install-graphify
brain-link-obsidian-cli
```

---

## Quick start

Unzip this package, then run:

```bash
cd obsidian-second-brain-setup
./scripts/setup-second-brain.sh
```

Then open Obsidian manually.

Inside Obsidian:

```text
Manage vaults
  → Open folder as vault
  → select ~/SecondBrain
```

Then enable the CLI:

```text
Settings
  → General
  → Command line interface
  → Enable
```

Restart your terminal and test:

```bash
obsidian help
```

If `obsidian` is not found, run:

```bash
brain-link-obsidian-cli
```

Then test again:

```bash
obsidian help
```

---

## Step 1: Run the setup script

```bash
./scripts/setup-second-brain.sh
```

You can choose a custom vault location:

```bash
SECOND_BRAIN="$HOME/Documents/SecondBrain" ./scripts/setup-second-brain.sh
```

The script will:

1. Create the vault folders.
2. Create starter notes.
3. Create Pi skills.
4. Install helper scripts into `~/bin`.
5. Initialise a Git repo.
6. Add a sensible `.gitignore`.
7. Commit the initial vault if Git is available.

---

## Step 2: Open the folder as an Obsidian vault

If Obsidian does not show “Create new vault”, use:

```text
Open folder as vault
```

Select:

```text
~/SecondBrain
```

You are not creating a “Base”. A vault is the whole Markdown folder. A Base is an Obsidian structured/table-style view over notes, which can come later.

---

## Step 3: Enable the Obsidian CLI

In Obsidian:

```text
Settings
  → General
  → Command line interface
  → Enable
```

Then restart your terminal.

Test:

```bash
obsidian help
```

If that fails, run:

```bash
brain-link-obsidian-cli
```

This tries to find the Obsidian CLI executable and symlink it to:

```bash
~/.local/bin/obsidian
```

Make sure this is in your shell path:

```bash
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
```

The setup script adds this to `~/.zshrc` if it is not already present.

---

## Step 4: Test the workflow

Capture a note:

```bash
brain-capture "Agent memory idea"
```

Run morning review:

```bash
brain-morning
```

Check Git status:

```bash
brain-status
```

Commit changes:

```bash
brain-save
```

Open the vault folder:

```bash
brain-open
```

---

## Step 5: Install Graphify

Optional but recommended:

```bash
brain-install-graphify
```

This tries to install Graphify using either `uv` or `pipx`.

Then run:

```bash
brain-graph
```

This creates:

```text
~/SecondBrain/graphify-out/
  GRAPH_REPORT.md
  graph.html
  graph.json
```

The graph is generated output. It is ignored by Git by default.

---

## Step 6: Use Pi from inside the vault

Run:

```bash
cd ~/SecondBrain
pi
```

Then try:

```text
/skill:second-brain
Review the vault structure and suggest what I should create next. Do not modify files yet.
```

For research:

```text
/skill:research-to-obsidian

Research the current state of Obsidian CLI, Pi skills, and Graphify for building an agent-readable second brain.

Create:
1. up to 5 source notes in 04-Resources/Web-Research
2. one synthesis note in 05-Permanent
3. one research log in 06-Agent/Research-Logs

Do not create huge notes.
Do not overwrite existing notes.
Mark everything as needs-review.
Prefer official docs and GitHub repositories.
```

---

## Recommended daily loop

```text
1. Capture rough ideas into 00-Inbox.
2. Let Pi help research, but only into reviewable notes.
3. Review notes in Obsidian.
4. Promote useful notes to 05-Permanent.
5. Run brain-graph after meaningful changes.
6. Commit with brain-save.
```

---

## Trust model

Do not let Pi write directly into trusted knowledge without review.

Use this ladder:

```text
00-Inbox
  raw thoughts

04-Resources/Web-Research
  sourced research

06-Agent/Research-Logs
  what the agent did

05-Permanent with status: needs-review
  proposed knowledge

05-Permanent with status: reviewed
  accepted knowledge
```

Your vault should distinguish:

```text
Pi found this
Pi thinks this
I reviewed this
I trust this enough to keep
```

---

## Files and scripts

### `scripts/setup-second-brain.sh`

Main setup script.

### `bin/brain-capture`

Creates a timestamped capture note in `00-Inbox`.

### `bin/brain-morning`

Opens/updates the daily note and shows review reminders.

### `bin/brain-graph`

Runs Graphify over the vault.

### `bin/brain-save`

Commits vault changes to Git.

### `bin/brain-status`

Shows Git status and recent changes.

### `bin/brain-open`

Opens the vault folder.

### `bin/brain-install-graphify`

Installs Graphify using `uv` or `pipx`.

### `bin/brain-link-obsidian-cli`

Attempts to symlink the Obsidian CLI into `~/.local/bin`.

---

## Notes

This is intentionally boring technology:

```text
Markdown
folders
Git
shell scripts
Obsidian
Pi skills
Graphify index
```

That is the point. Boring is portable, inspectable, scriptable, and hard to trap inside a SaaS product.

